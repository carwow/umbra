package reporter

import (
	"github.com/carwow/umbra/pool"
)

type Reporter interface {
	Inc()
	Consume()
	Report() Stats
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
	channel <-chan *pool.Result
	stats   *Stats
}

// New returns a new Reporter
func New(channel <-chan *pool.Result) *Config {
	return &Config{
		channel: channel,
		stats:   &Stats{},
	}
}

// Consume receives from the results chan and store them for later reporting
func (c *Config) Consume() {
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
}

// Inc increments the 'total processed' counter.
func (c *Config) Inc() {
	c.stats.ProcessedTotal++
}

// Report returns the current aggregate results of this shadowing run
func (c *Config) Report() Stats {
	return *c.stats
}
