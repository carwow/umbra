module Umbra
  class ShadowRequester
    attr_reader :queue, :count

    def initialize(count: 1, pool: 1, max_queue_size: 100)
      @count = count
      @queue ||= Concurrent::CachedThreadPool.new(
        min_threads: 1,
        max_threads: pool,
        max_queue: max_queue_size,
        fallback_policy: :abort
      )
    end

    def call(env)
      queue << proc { call!(env) }

      true
    rescue Concurrent::RejectedExecutionError
      Umbra.logger.warn "[umbra] Shadowing queue at max - dropping items"

      false
    end

    def call!(env)
      hydra = Typhoeus::Hydra.new
      request = RequestBuilder.call(env)

      @count.times { hydra.queue(request) }

      hydra.run
    end
  end
end
