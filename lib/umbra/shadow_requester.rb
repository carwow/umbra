module Umbra
  class ShadowRequester
    def initialize(count: 1, pool: 1, max_queue_size: 100)
      @count = count
      @pool = pool
      @queue = Queue.new
      @stop = Object.new
      @lock = Mutex.new
      @max_queue_size = max_queue_size
    end

    def call(env)
      start_worker!

      if @queue.size > @max_queue_size
        Umbra.logger.warn '[umbra] Shadowing queue at max - dropping items'
        return
      end

      request = RequestBuilder.call(env)

      @count.times { @queue.push(request) }
    end

    private

    def start_worker!
      @lock.synchronize do
        return if @started

        @started = true
        Umbra.logger.info '[umbra] Starting shadowing threads...'

        workers = (1..@pool).map do |thread_num|
          Thread.new do
            Umbra.logger.info "[umbra] shadow thread #{thread_num} waiting"

            while (request = @queue.pop)
              break if request == @stop

              begin
                request.run
              rescue StandardError => e
                Umbra.logger.warn "[umbra] error in shadow thread #{thread_num}"
                Umbra.config.error_handler.call(e)
              end
            end
          end
        end

        at_exit do
          @pool.times { @queue.push(@stop) }
          workers.map(&:join)
        end
      end
    end
  end
end
