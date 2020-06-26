package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/carwow/umbra/dispatcher"
	"github.com/carwow/umbra/pool"
	"github.com/carwow/umbra/reporter"
	"github.com/go-redis/redis/v8"
)

const (
	defaultRedisURL          = "redis://localhost:6379"
	defaultRedisChannel      = "umbra_channel"
	defaultRequestBufferSize = 25
	defaultTimeout           = 5 * time.Second
	defaultWorkers           = 100
	defaultReplication       = 1
)

func init() {
	log.SetPrefix("[umbra] ")
	log.SetFlags(log.Lmsgprefix | log.LstdFlags)
}

// builds and ping the redis connection
func initRedis(url string) *redis.Client {
	options, err := redis.ParseURL(url)
	if err != nil {
		log.Fatalf("failed to parse redis URL(%v): %v", defaultRedisURL, err)
	}

	client := redis.NewClient(options)
	if err := client.Ping(context.TODO()).Err(); err != nil {
		log.Fatalf("failed to ping redis %v", err)
	}

	return client
}

// builds and pings the redis subscription
func initPubsub(redisClient *redis.Client, channel string) *redis.PubSub {
	pubsub := redisClient.Subscribe(context.TODO(), defaultRedisChannel)

	_, err := pubsub.Receive(context.TODO())
	if err != nil {
		log.Fatal("error setting up subscription!")
	}

	return pubsub
}

// waits for SIGTERM and runs draining and teardown of workers
func waitForInterrupt(pubsub *redis.PubSub, p pool.Pool, redisClient *redis.Client, wg *sync.WaitGroup) {
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)

	<-c // wait for signal

	log.Println("got SIGTERM")
	log.Println("unsubscribing...")
	pubsub.Close()

	log.Println("stopping workers...")
	p.Stop()

	log.Println("closing redis conn...")
	redisClient.Close()

	wg.Wait()
}

func report(r reporter.Reporter) {
	report := r.Report()

	log.Printf(" * Report\n")
	log.Printf("\tTotal Processed:    %v\n", report.ProcessedTotal)
	log.Printf("\tTotal Replicated:   %v\n", report.ReplicatedTotal)
	log.Printf("\tTotal Errored:      %v\n", report.ErroredTotal)
	log.Printf("\tTotal Server Error: %v\n", report.ServerErrorTotal)
	log.Printf("\tTotal Server OK:    %v\n", report.ServerOKTotal)
	log.Printf("\tTotal DurationMs:   %v\n", report.TotalDurationMs)
}

func main() {
	redisURL := flag.String("redis", defaultRedisURL, "redis connection string")
	workers := flag.Int("workers", defaultWorkers, "number of concurrent workers")
	buffer := flag.Int("buffer", defaultRequestBufferSize, "request buffer size")
	timeout := flag.Duration("timeout", defaultTimeout, "http client timeout duration")
	replication := flag.Float64("replication", defaultReplication, "number of times to replicate requests")

	flag.Parse()

	client := initRedis(*redisURL)
	pubsub := initPubsub(client, defaultRedisChannel)
	channel := pubsub.ChannelSize(*buffer)

	p := pool.New(*workers, *buffer, *timeout).Start()
	r := reporter.New(p.ResultsChannel())
	d := dispatcher.New(p, r, channel, *replication)

	var wg sync.WaitGroup

	// Consume Redis Messages
	go func() {
		wg.Add(1)
		defer wg.Done()

		d.Consume()

		log.Println("stopped consuming messages...")
	}()

	// Consume replication results
	go func() {
		wg.Add(1)
		defer wg.Done()

		r.Consume()
		log.Println("stopped consuming results...")
	}()

	// Report stats
	go func() {
		for {
			time.Sleep(5 * time.Second)

			report(r)
		}
	}()

	log.Println("ready!")

	waitForInterrupt(pubsub, p, client, &wg)

	os.Exit(0)
}
