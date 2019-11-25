module Umbra
  class ShadowRequester
    def initialize(count: 1, pool: 1, max_queue_size: 100)
      @count = count
      @pool = pool
      @max_queue_size = max_queue_size
    end

    def call(env)
      @count.times do
        queue << proc { RequestBuilder.call(env).run }
      end

      true
    rescue Concurrent::RejectedExecutionError
      Umbra.logger.warn '[umbra] Shadowing queue at max - dropping items'

      false
    end

    private

    def queue
      @queue ||= Concurrent::CachedThreadPool.new(
        min_threads: 1,
        max_threads: @pool,
        max_queue: @max_queue_size,
        fallback_policy: :abort
      )
    end
  end
end
