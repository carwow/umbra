package main

import (
	"flag"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/carwow/umbra/collector"
	"github.com/carwow/umbra/dispatcher"
	"github.com/carwow/umbra/pool"
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

// waits for SIGTERM and runs draining and teardown of workers
func waitForInterrupt(d dispatcher.Dispatcher, p pool.Pool, c collector.Collector) {
	s := make(chan os.Signal)
	signal.Notify(s, os.Interrupt, syscall.SIGTERM)

	<-s // wait for signal

	// stop the dispatcher, stopping incoming requests to be replicated
	d.Stop()

	// stop the work pool, stopping replications
	p.Stop()

	// stop the collector, there is nothing more to collect
	c.Stop()
}

func report(r collector.Collector) {
	report := r.Stats()

	log.Printf(" * Report\n")
	log.Printf("\tTotal Processed:    %v\n", report.ProcessedTotal)
	log.Printf("\tTotal Replicated:   %v\n", report.ReplicatedTotal)
	log.Printf("\tTotal Errored:      %v\n", report.ErroredTotal)
	log.Printf("\tTotal Timeout:      %v\n", report.TimeoutErrorTotal)
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

	c := collector.New(*buffer).Start()
	p := pool.New(*workers, *buffer, *timeout, c).Start()
	d := dispatcher.New(p, c, *redisURL, defaultRedisChannel, *buffer, *replication).Start()

	log.Println("ready!")

	go func() {
		for {
			time.Sleep(time.Second * 5)
			report(c)
		}
	}()

	waitForInterrupt(d, p, c)

	os.Exit(0)
}
