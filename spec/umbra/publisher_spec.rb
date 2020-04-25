# frozen_string_literal: true

RSpec.describe Umbra::Publisher do
  let(:env) { "env" }
  let(:response) { "response" }
  let(:encoder) { instance_double("Encoder", call: "encoded") }
  let(:redis) { instance_double("Redis", publish: nil) }
  let(:instance) { described_class.new }

  describe ".call!" do
    it "calls the encoder" do
      instance.call!(env, response, encoder: encoder, redis: redis)

      expect(encoder).to have_received(:call).with(env, response)
    end

    it "calls redis" do
      instance.call!(env, response, encoder: encoder, redis: redis)

      expect(redis).to have_received(:publish).with(Umbra::CHANNEL, "encoded")
    end
  end
end
