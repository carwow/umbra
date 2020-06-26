package pool

import (
	"github.com/carwow/umbra/collector"

	"io"
	"io/ioutil"
	"log"
	"net/http"
	"sync"
	"time"
)

// Pool describes a worker pool interface
type Pool interface {
	Add(*http.Request, int) int
	Start() Pool
	Stop()
}

// The Config struct contains the internal configuration for a Pool
type Config struct {
	client      *http.Client
	channel     chan *http.Request
	concurrency int
	collect     collector.Collector
	wg          sync.WaitGroup
}

// New builds a new Pool
func New(concurrency, buffer int, timeout time.Duration, collect collector.Collector) *Config {
	return &Config{
		collect:     collect,
		channel:     make(chan *http.Request, buffer),
		client:      &http.Client{Timeout: timeout},
		concurrency: concurrency,
	}
}

// Start begins the background workers for the pool
func (pool *Config) Start() Pool {
	for i := 0; i < pool.concurrency; i++ {
		go pool.work()
	}

	return pool
}

// Add pushes an item of work to the pool n times, returns the number of items of
// work that were succeesfully pushed. The returned number may be less than n
// when the work channel buffer is full.
func (pool *Config) Add(request *http.Request, n int) int {
	var pushed int

	for i := 0; i < n; i++ {
		select {
		case pool.channel <- request:
			pushed++
		default:
		}
	}

	return pushed
}

// Stop closes the work channel, causing all workers to stop, it then closes
// the ResultsChan.
func (pool *Config) Stop() {
	close(pool.channel)

	log.Printf("pool stopped, queue: %v\n", len(pool.channel))

	pool.wg.Wait()
}

func (pool *Config) work() {
	pool.wg.Add(1)
	defer pool.wg.Done()

	for request := range pool.channel {
		start := time.Now()
		resp, err := pool.client.Do(request)
		result := &collector.Result{
			Timestamp:  start,
			DurationMs: uint64(time.Now().Sub(start).Milliseconds()),
		}

		if err != nil {
			result.Err = err
		} else {
			io.Copy(ioutil.Discard, resp.Body)
			resp.Body.Close()
			result.Status = resp.StatusCode
		}

		pool.collect.Add(result)
	}
}
