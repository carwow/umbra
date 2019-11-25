module Umbra
  class Publisher < SynchronousPublisher
    MAX_QUEUE_SIZE = 100

    class << self
      def call(env, response)
        pool << proc { super.call(env, response) }

        true
      rescue Concurrent::RejectedExecutionError
        Umbra.logger.warn '[umbra] Queue at max - dropping items'

        false
      end

      private

      def pool
        LOCK.synchronize do
          @pool ||= Concurrent::CachedThreadPool.new(
            min_threads: 1,
            max_threads: 1,
            max_queue: MAX_QUEUE_SIZE,
            fallback_policy: :abort
          )
        end
      end
    end

    LOCK = Mutex.new
    private_constant :LOCK
  end
end
