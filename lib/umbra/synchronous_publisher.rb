module Umbra
  class SynchronousPublisher
    def self.call(env, response, encoder: Umbra.encoder, redis: Umbra.redis)
      redis.publish(Umbra::CHANNEL, encoder.call(env, response))
    end
  end
end
