module Umbra
  class Publisher < SynchronousPublisher
    MAX_QUEUE_SIZE = 100

    class << self
      def call(env, response)
        start_once!

        if @queue.size > MAX_QUEUE_SIZE
          Umbra.logger.warn '[umbra] Publish queue at max - dropping items'
          return
        end

        @queue.push(proc { super(env, response) })
      end

      private

      def start_once!
        LOCK.synchronize do
          return if @started == Process.pid

          Umbra.logger.info '[umbra] Starting publishing thread'

          @started = Process.pid
          @queue = Queue.new

          worker_thread = Thread.new do
            while (x = @queue.pop)
              break if x == STOP

              begin
                x.call
              rescue StandardError => e
                Umbra.logger.warn '[umbra] Error in publishing thread'
                Umbra.config.error_handler.call(e)
              end
            end
          end

          at_exit do
            @queue.push(STOP)
            worker_thread.join
          end
        end
      end
    end

    STOP = Object.new
    LOCK = Mutex.new
    private_constant :STOP, :LOCK
  end
end
