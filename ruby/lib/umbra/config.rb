module Umbra
  class Config
    attr_accessor :publisher, :request_selector, :encoder, :error_handler, :redis_options, :logger

    def self.default(&block)
      new(
        publisher: Publisher.new,
        request_selector: RequestSelector,
        encoder: Encoder,
        error_handler: SuppressErrorHandler,
        redis_options: {},
        logger: Logger.new(STDOUT),
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
      @logger = opts.fetch(:logger)

      yield(self) if block_given?
    end
  end
end
