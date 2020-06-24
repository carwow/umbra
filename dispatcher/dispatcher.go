package dispatcher

import (
	"github.com/carwow/umbra/pb"
	"github.com/carwow/umbra/pool"
	"github.com/carwow/umbra/reporter"

	"bytes"
	"github.com/go-redis/redis/v8"
	"google.golang.org/protobuf/proto"
	"log"
	"math/rand"
	"net/http"
)

// Config contains configuration for the dispatcher
type Config struct {
	channel     <-chan *redis.Message
	pool        pool.Pool
	report      *reporter.Config
	replication float64
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

	return r, nil
}

// New returns a configured dispatcher
func New(pool pool.Pool, report *reporter.Config, channel <-chan *redis.Message, replication float64) *Config {
	return &Config{
		pool:        pool,
		report:      report,
		channel:     channel,
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

// Consume receives from the configured redis channel, converts the message into
// a http.Request and pushes it to the pool for replication the configured number
// of times
func (c *Config) Consume() {
	var pbMsg pb.Message
	var rep int

	for msg := range c.channel {
		c.report.Inc()

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
			log.Printf("queue is full, dropped %v replications\n", dropped)
		}
	}
}
