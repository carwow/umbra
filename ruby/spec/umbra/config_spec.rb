# frozen_string_literal: true

RSpec.describe Umbra::Config do
  describe ".default" do
    let(:config) { described_class.default }

    it { expect(config.publisher).to be_a(Umbra::Publisher) }
    it { expect(config.request_selector).to eq(Umbra::RequestSelector) }
    it { expect(config.error_handler).to eq(Umbra::SuppressErrorHandler) }
    it { expect(config.redis_options).to eq({}) }

    context "with block" do
      let(:config) do
        described_class.default do |config|
          config.publisher = "publisher"
          config.request_selector = "request_selector"
          config.error_handler = "error_handler"
          config.redis_options = "redis_options"
          config.logger = "logger"
        end
      end

      it { expect(config.publisher).to eq("publisher") }
      it { expect(config.request_selector).to eq("request_selector") }
      it { expect(config.error_handler).to eq("error_handler") }
      it { expect(config.redis_options).to eq("redis_options") }
      it { expect(config.logger).to eq("logger") }
    end
  end
end
