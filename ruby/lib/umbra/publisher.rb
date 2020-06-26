module Umbra
  class Publisher
    DEFAULT_MAX_QUEUE = 100
    DEFAULT_MIN_THREADS = 1
    DEFAULT_MAX_THREADS = 1

    attr_reader :pool

    def initialize(**options)
      @pool = Concurrent::CachedThreadPool.new(
        min_threads: options.fetch(:min_threads, DEFAULT_MIN_THREADS),
        max_threads: options.fetch(:max_thread, DEFAULT_MAX_THREADS),
        max_queue: options.fetch(:max_queue, DEFAULT_MAX_QUEUE),
        fallback_policy: :abort
      )
    end

    def call(env, encoder: Umbra.encoder, redis: Umbra.redis)
      @pool << proc { call!(env, encoder: encoder, redis: redis) }

      true
    rescue Concurrent::RejectedExecutionError
      Umbra.logger.warn "[umbra] Queue at max - dropping items"

      false
    end

    def call!(env, encoder: Umbra.encoder, redis: Umbra.redis)
      redis.publish(Umbra::CHANNEL, encoder.call(env))
    end
  end
end
