# frozen_string_literal: true

RSpec.describe Umbra do
  around do |example|
    described_class.configure
    example.run
    described_class.reset!
  end

  it "has a version number" do
    expect(Umbra::VERSION).not_to be nil
  end

  describe ".publish" do
    let(:request_body) { instance_double(IO, rewind: nil, read: "body") }
    let(:env) { {"rack.input" => request_body} }
    let(:config) { described_class.config }
    let(:publisher) { config.publisher }
    let(:request_selector) { config.request_selector }
    let(:error_handler) { config.error_handler }
    let(:expected_env) { {"rack.input" => request_body, "umbra.request_body" => "body"} }

    before do
      allow(publisher).to receive(:call)
      allow(error_handler).to receive(:call)
    end

    it "calls the configured publisher" do
      described_class.publish(env)

      expect(publisher).to have_received(:call).with(expected_env)
    end

    it "calls the configured request_selector" do
      allow(request_selector).to receive(:call).and_call_original

      described_class.publish(env)

      expect(request_selector).to have_received(:call).with(env)
    end

    context "when its an umbra request" do
      let(:env) { {Umbra::HEADER_KEY => Umbra::HEADER_VALUE} }

      it "does not call publisher" do
        described_class.publish(env)

        expect(publisher).not_to have_received(:call)
      end
    end

    context "when request selector returns false" do
      it "does not call publisher" do
        config.request_selector = proc { false }

        described_class.publish(env)

        expect(publisher).not_to have_received(:call)
      end
    end

    context "when publisher errors" do
      let(:error) { StandardError.new }

      it "calls the error_handler" do
        allow(publisher).to receive(:call).and_raise(error)

        described_class.publish(env)

        expect(error_handler).to have_received(:call).with(error, env)
      end
    end
  end
end
