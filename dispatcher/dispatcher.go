package dispatcher

import (
	"github.com/carwow/umbra/collector"
	"github.com/carwow/umbra/pb"
	"github.com/carwow/umbra/pool"

	"bytes"
	"context"
	"github.com/go-redis/redis/v8"
	"google.golang.org/protobuf/proto"
	"log"
	"math/rand"
	"net/http"
	"sync"
)

// The Dispatcher basically ETLs from a datasource (e.g. a redis channel) to
// a processor (i.e. a pool.Pool) a configurable number of times
type Dispatcher interface {
	Start() Dispatcher
	Stop()
}

// Config contains configuration for the dispatcher
type Config struct {
	pool    pool.Pool
	collect collector.Collector

	channel     <-chan *redis.Message
	client      *redis.Client
	pubsub      *redis.PubSub
	replication float64

	wg sync.WaitGroup
}

// ToHTTPRequest converts a protobuf message into an http.Request
func ToHTTPRequest(msg *pb.Message) (*http.Request, error) {
	r, err := http.NewRequest(msg.Method, msg.Url, bytes.NewReader(msg.Body))
	if err != nil {
		return nil, err
	}

	for k, v := range msg.Headers {
		r.Header.Add(k, v)
	}

	r.Header.Add("Cache-Control", "no-cache")

	return r, nil
}

// New returns a configured dispatcher
func New(pool pool.Pool, collect collector.Collector, url, redisChannel string, buffer int, replication float64) *Config {
	options, err := redis.ParseURL(url)
	if err != nil {
		log.Fatalf("failed to parse redis url (%v): %v", url, err)
	}

	client := redis.NewClient(options)
	if err := client.Ping(context.TODO()).Err(); err != nil {
		log.Fatalf("failed to ping redis: %v", err)
	}

	pubsub := client.Subscribe(context.TODO(), redisChannel)
	if _, err := pubsub.Receive(context.TODO()); err != nil {
		log.Fatalf("failed to ping redis channel: %v", err)
	}

	return &Config{
		pool:        pool,
		collect:     collect,
		channel:     pubsub.ChannelSize(buffer),
		client:      client,
		pubsub:      pubsub,
		replication: replication,
	}
}

// Replications returns the number of replication that should be pushed to the
// pool
func (c *Config) Replications(random float64) int {
	intPart := int(c.replication)
	floatPart := c.replication - float64(intPart)

	if floatPart > random {
		intPart++
	}

	return intPart
}

// Stop stops consuming the redis channel and cleans up resources
func (c *Config) Stop() {
	c.pubsub.Close()
	c.wg.Wait()
	c.client.Close()
}

// Start receives from the configured redis channel, converts the message into
// a http.Request and pushes it to the pool for replication the configured number
// of times
func (c *Config) Start() Dispatcher {
	c.wg.Add(1)
	defer c.wg.Done()

	go func() {
		var pbMsg pb.Message
		var rep int

		for msg := range c.channel {
			c.collect.Inc()

			if err := proto.Unmarshal([]byte(msg.Payload), &pbMsg); err != nil {
				log.Println("protobuf error:", err)

				continue
			}

			httpReq, err := ToHTTPRequest(&pbMsg)
			if err != nil {
				log.Println("http request building error:", err)

				continue
			}

			reps := c.Replications(rand.Float64())
			rep = c.pool.Add(httpReq, reps)

			if dropped := reps - rep; dropped != 0 {
				log.Printf("pool queue is full, dropped %v replications\n", dropped)
			}
		}

		log.Printf("dispatcher stopped, queue: %v\n", len(c.channel))
	}()

	return c
}
