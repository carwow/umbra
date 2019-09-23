module Umbra
  class ShadowRequester
    def initialize(count: 1, pool: 1)
      @count = count
      @pool = pool
      @queue = Queue.new
      @stop = Object.new
      @lock = Mutex.new
    end

    def call(env)
      start_worker!

      request = RequestBuilder.call(env)

      @count.times { @queue.push(request) }
    end

    private

    def start_worker!
      @lock.synchronize do
        return if @started

        @started = true

        workers = (1..@pool).map do |_|
          Thread.new do
            while (request = @queue.pop)
              break if request == @stop

              request.run
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
