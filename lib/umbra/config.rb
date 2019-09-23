module Umbra
  class Config
    attr_accessor :publisher, :request_selector, :encoder, :error_handler, :redis_options

    def self.default(&block)
      new(
        publisher: Publisher,
        request_selector: RequestSelector,
        encoder: Encoder,
        error_handler: SuppressErrorHandler,
        redis_options: {},
        &block
      )
    end

    private

    def initialize(opts)
      @publisher = opts.fetch(:publisher)
      @request_selector = opts.fetch(:request_selector)
      @encoder = opts.fetch(:encoder)
      @error_handler = opts.fetch(:error_handler)
      @redis_options = opts.fetch(:redis_options)

      yield(self) if block_given?
    end
  end
end
