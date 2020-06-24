package pool

import (
	"io"
	"io/ioutil"
	"net/http"
	"sync"
	"time"
)

// Pool describes a worker pool interface
type Pool interface {
	ResultsChannel() <-chan *Result
	Add(*http.Request, int) int
	Start() Pool
	Stop()
}

// The Result struct contains information related to the status of a single
// replication attempt
type Result struct {
	Timestamp  time.Time
	Status     int
	DurationMs uint64
	Err        error
}

// The Config struct contains the internal configuration for a Pool
type Config struct {
	resultsChan chan *Result
	client      *http.Client
	workChan    chan *http.Request
	concurrency int
	wg          sync.WaitGroup
}

// New builds a new Pool
func New(concurrency, buffer int, timeout time.Duration) *Config {
	return &Config{
		resultsChan: make(chan *Result, buffer),
		workChan:    make(chan *http.Request, buffer),
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
		case pool.workChan <- request:
			pushed++
		default:
		}
	}

	return pushed
}

// Stop closes the work channel, causing all workers to stop, it then closes
// the ResultsChan.
func (pool *Config) Stop() {
	close(pool.workChan)

	pool.wg.Wait()

	close(pool.resultsChan)
}

// ResultsChannel returns the channel upon which results will be pushed. If a
// consumer does not receive from this channel, workers will stall, waiting for
// the channel to be free.
func (pool *Config) ResultsChannel() <-chan *Result {
	return pool.resultsChan
}

func (pool *Config) work() {
	pool.wg.Add(1)
	defer pool.wg.Done()

	for request := range pool.workChan {
		start := time.Now()
		resp, err := pool.client.Do(request)
		result := &Result{
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

		pool.resultsChan <- result
	}
}
