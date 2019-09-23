module Umbra
  class Publisher < SynchronousPublisher
    class << self
      def call(env, response)
        start_once!

        @queue.push(proc { super(env, response) })
      end

      private

      def start_once!
        LOCK.synchronize do
          return if @started == Process.pid

          @started = Process.pid
          @queue = Queue.new

          worker_thread = Thread.new do
            while (x = @queue.pop)
              break if x == STOP

              x.call
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
