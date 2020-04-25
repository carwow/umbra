# frozen_string_literal: true

require "typhoeus"
require "redis"
require "multi_json"
require "concurrent"

module Umbra
  autoload :Config, "umbra/config"
  autoload :Encoder, "umbra/encoder"
  autoload :Middleware, "umbra/middleware"
  autoload :Publisher, "umbra/publisher"
  autoload :Subscriber, "umbra/subscriber"
  autoload :RequestBuilder, "umbra/request_builder"
  autoload :ShadowRequester, "umbra/shadow_requester"
  autoload :SynchronousPublisher, "umbra/synchronous_publisher"
  autoload :Version, "umbra/version"

  CHANNEL = "umbra_channel"
  HEADER_KEY = "HTTP_X_UMBRA_REQUEST"
  HEADER_VALUE = "true"

  RequestSelector = proc { true }
  SuppressErrorHandler = proc { nil }

  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.default(&block)

      test_redis_connection!
    end

    def publish(env, response)
      return if umbra_request?(env)
      return unless @config
      return unless @config.request_selector.call(env, response)

      env["umbra.request_body"] = request_body(env)

      @config.publisher.call(env, response)
    rescue => e
      @config.error_handler.call(e, env, response)
    end

    def redis
      @redis ||= Redis.new(@config.redis_options)
    end

    def encoder
      @config.encoder
    end

    def logger
      @config.logger
    end

    def reset!
      @config = nil
      @redis = nil
    end

    private

    def request_body(env)
      io = env.fetch("rack.input")
      io.rewind
      body = io.read
      io.rewind

      body
    end

    def test_redis_connection!
      logger.info "[umbra] Testing redis connection..."
      redis.ping
      logger.info "[umbra] redis is alive!"
    rescue Redis::BaseError => e
      logger.warn "[umbra] error while connecting to redis: #{e.message}"
      reset!
    rescue => e
      logger.warn "[umbra] redis is misconfigured: #{e.message}"
      reset!
    end

    def umbra_request?(env)
      env[HEADER_KEY] == HEADER_VALUE
    end
  end
end
