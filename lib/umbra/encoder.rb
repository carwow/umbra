# frozen_string_literal: true

module Umbra
  class Encoder
    def self.call(env)
      new(env).call
    end

    def initialize(env)
      @env = env
    end

    def call
      @call ||= Pb::Message.new(
        method: rack_request.request_method,
        url: rack_request.url,
        body: request_body,
        headers: request_headers
      ).to_proto
    end

    def ignored_headers
      []
    end

    private

    def rack_request
      @rack_request ||= Rack::Request.new(@env)
    end

    def request_headers
      @request_headers ||=
        @env
          .select { |k, _| k.start_with?("HTTP_") && !ignored_headers.include?(k) }
          .merge(HEADER_KEY => HEADER_VALUE)
          .transform_keys { |k| to_http_header(k) }
    end

    def to_http_header(rack_header)
      rack_header.delete_prefix("HTTP_").downcase.split("_").join("-")
    end

    def request_body
      @env.fetch("umbra.request_body")
    end
  end
end
