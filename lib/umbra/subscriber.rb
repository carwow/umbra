module Umbra
  class Subscriber
    def initialize(worker, redis: Umbra.redis)
      @worker = worker
      @redis = redis
    end

    def start
      @redis.ensure_connected do
        @redis.subscribe(Umbra::CHANNEL) do |on|
          on.message do |_, message|
            @worker.call(MultiJson.load(message))
          end
        end
      end
    end
  end
end
