module Umbra
  class Subscriber
    def initialize(worker)
      @worker = worker
    end

    def start
      Umbra.redis.subscribe(Umbra::CHANNEL) do |on|
        on.message do |_, message|
          @worker.call(MultiJson.load(message))
        end
      end
    end
  end
end
