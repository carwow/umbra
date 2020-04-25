# frozen_string_literal: true

module Umbra
  class Encoder
    def self.call(env, response)
      new(env, response).call
    end

    def initialize(env, response)
      @env = env
      @status, @headers, @body = response
    end

    def to_h
      @to_h ||=
        {
          "request" => {
            "scheme" => @env.fetch("rack.url_scheme"),
            "host" => @env["HTTP_HOST"] || @env.fetch("SERVER_NAME"),
            "uri" => @env.fetch("REQUEST_URI"),
            "port" => @env.fetch("SERVER_PORT"),
            "method" => @env.fetch("REQUEST_METHOD"),
            "query" => @env.fetch("QUERY_STRING"),
            "script_name" => @env.fetch("SCRIPT_NAME"),
            "path_info" => @env.fetch("PATH_INFO"),
            "headers" => request_headers,
            "body" => request_body
          },
          "response" => {
            "status" => @status,
            "headers" => @headers,
            "body" => body_string
          }
        }
    end

    def call
      @call ||= MultiJson.dump(to_h)
    end

    private

    def request_headers
      @request_headers ||= @env.select { |k, _| k.start_with?("HTTP_") }
    end

    def request_body
      @env.fetch("umbra.request_body")
    end

    def body_string
      @body_string ||=
        begin
          str = []

          @body.each { |x| str << x.to_s }

          str.join("")
        end
    end
  end
end
