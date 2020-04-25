# frozen_string_literal: true

module Umbra
  class RequestBuilder
    UMBRA_HEADERS = {
      Umbra::HEADER_KEY => Umbra::HEADER_VALUE,
      "HTTP_CACHE_CONTROL" => "no-cache, no-store, private, max-age=0"
    }.freeze

    class << self
      def call(env)
        Typhoeus::Request.new(
          base_url(env) + url(env),
          method: method(env),
          body: body(env),
          headers: headers(env)
        )
      end

      private

      def headers(env)
        request(env)
          .fetch("headers")
          .merge(UMBRA_HEADERS)
          .transform_keys { |key| key.split("_").drop(1).map(&:capitalize).join("-") }
      end

      def method(env)
        request(env).fetch("method").downcase.to_sym
      end

      def body(env)
        request(env).fetch("body")
      end

      def url(env)
        request = request(env)
        query = request.fetch("query")
        path = request.fetch("script_name") + request.fetch("path_info")

        query.empty? ? path : path + "?#{query}"
      end

      def base_url(env)
        request = request(env)
        scheme = request.fetch("scheme")
        host = request.fetch("host")

        "#{scheme}://#{host}"
      end

      def request(env)
        env.fetch("request")
      end
    end
  end
end
