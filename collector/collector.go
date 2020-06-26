package collector

import (
	"fmt"
	"log"
	"sync"
	"time"
)

type Collector interface {
	Add(*Result) error
	Inc()
	Start() Collector
	Stop()
	Stats() Stats
}

// The Result struct contains information related to the status of a single
// replication attempt
type Result struct {
	Timestamp  time.Time
	Status     int
	DurationMs uint64
	Err        error
}

// Stats contains stats around the current reporting run
type Stats struct {
	ProcessedTotal   uint64
	ReplicatedTotal  uint64
	ErroredTotal     uint64
	ServerErrorTotal uint64
	ServerOKTotal    uint64
	TotalDurationMs  uint64
}

// Config contains the internal configuration for a worker
type Config struct {
	channel chan *Result
	stats   *Stats
	wg      sync.WaitGroup
}

// New returns a new Reporter
func New(buffer int) *Config {
	return &Config{
		channel: make(chan *Result, buffer),
		stats:   &Stats{},
	}
}

// Consume receives from the results chan and store them for later reporting
func (c *Config) Start() Collector {
	go func() {
		c.wg.Add(1)
		defer c.wg.Done()

		for result := range c.channel {
			c.stats.ReplicatedTotal++

			if result.Err != nil {
				c.stats.ErroredTotal++
			} else if result.Status < 500 {
				c.stats.ServerOKTotal++
				c.stats.TotalDurationMs = c.stats.TotalDurationMs + result.DurationMs
			} else {
				c.stats.ServerErrorTotal++
				c.stats.TotalDurationMs = c.stats.TotalDurationMs + result.DurationMs
			}
		}

		log.Printf("collector stopped, queue: %v\n", len(c.channel))
	}()

	return c
}

func (c *Config) Add(res *Result) error {
	select {
	case c.channel <- res:
		return nil
	default:
		return fmt.Errorf("result channel full")
	}
}

func (c *Config) Stop() {
	close(c.channel)
	c.wg.Wait()
}

// Inc increments the 'total processed' counter.
func (c *Config) Inc() {
	c.stats.ProcessedTotal++
}

// Report returns the current aggregate results of this shadowing run
func (c *Config) Stats() Stats {
	return *c.stats
}
