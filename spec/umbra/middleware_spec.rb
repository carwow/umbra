# frozen_string_literal: true

RSpec.describe Umbra::Middleware do
  let(:app) { proc { [200, {"User-Agent" => "hello"}, ["a body"]] } }
  let(:instance) { described_class.new(app) }

  describe "#call" do
    before { allow(Umbra).to receive(:publish) }

    it "calls Umbra.publish with expected params" do
      instance.call("env")

      expect(Umbra).to have_received(:publish).with("env")
    end

    it "does not alter rack response" do
      expect(instance.call("env")).to eq([200, {"User-Agent" => "hello"}, ["a body"]])
    end
  end
end
