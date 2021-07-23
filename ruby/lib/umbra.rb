# frozen_string_literal: true

require "zeitwerk"
require "rack"
require "redis"
require "concurrent"

Zeitwerk::Loader.for_gem.setup

module Umbra
  autoload :Pb, "umbra/pb/umbra_pb"

  CHANNEL = "umbra_channel"
  HEADER_KEY = "HTTP_X_UMBRA_REQUEST"
  HEADER_VALUE = "true"

  RequestSelector = proc { true }
  SuppressErrorHandler = proc {}

  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.default(&block)

      test_redis_connection!
    end

    def publish(env)
      return if umbra_request?(env)

      return unless @config
      return unless @config.request_selector.call(env)

      env["umbra.request_body"] = request_body(env)

      @config.publisher.call(env)
    rescue => e
      @config.error_handler.call(e, env)
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
