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

    def call
      MultiJson.dump(
        'request' => {
          'scheme' => @env.fetch('rack.url_scheme'),
          'host' => @env['HTTP_HOST'] || @env.fetch('SERVER_NAME'),
          'uri' => @env.fetch('REQUEST_URI'),
          'port' => @env.fetch('SERVER_PORT'),
          'method' => @env.fetch('REQUEST_METHOD'),
          'query' => @env.fetch('QUERY_STRING'),
          'script_name' => @env.fetch('SCRIPT_NAME'),
          'path_info' => @env.fetch('PATH_INFO'),
          'headers' => request_headers,
          'body' => request_body
        },
        'response' => {
          'status' => @status,
          'headers' => @headers,
          'body' => body_string
        }
      )
    end

    private

    def request_headers
      @env.select { |k, _| k.start_with?('HTTP_') }
    end

    def request_body
      io = @env.fetch('rack.input')

      io.rewind
      body = io.read
      io.rewind

      body
    end

    def body_string
      str = []

      @body.each { |x| str << x.to_s }

      str.join('')
    end
  end
end
