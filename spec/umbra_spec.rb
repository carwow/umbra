# frozen_string_literal: true

RSpec.describe Umbra do
  around do |example|
    described_class.configure
    example.run
    described_class.reset!
  end

  it 'has a version number' do
    expect(Umbra::VERSION).not_to be nil
  end

  describe '.publish' do
    let(:env) { {} }
    let(:response) { nil }
    let(:config) { described_class.config }
    let(:publisher) { config.publisher }
    let(:request_selector) { config.request_selector }
    let(:error_handler) { config.error_handler }

    before do
      allow(publisher).to receive(:call)
      allow(error_handler).to receive(:call)
    end

    it 'calls the configured publisher' do
      described_class.publish(env, response)

      expect(publisher).to have_received(:call).with(env, response)
    end

    it 'calls the configured request_selector' do
      allow(request_selector).to receive(:call).and_call_original

      described_class.publish(env, response)

      expect(request_selector).to have_received(:call).with(env, response)
    end

    context 'when its an umbra request' do
      let(:env) { { Umbra::HEADER_KEY => Umbra::HEADER_VALUE } }

      it 'does not call publisher' do
        described_class.publish(env, response)

        expect(publisher).not_to have_received(:call)
      end
    end

    context 'when request selector returns false' do
      it 'does not call publisher' do
        config.request_selector = proc { false }

        described_class.publish(env, response)

        expect(publisher).not_to have_received(:call)
      end
    end

    context 'when publisher errors' do
      let(:error) { StandardError.new }

      it 'calls the error_handler' do
        allow(publisher).to receive(:call).and_raise(error)

        described_class.publish(env, response)

        expect(error_handler).to have_received(:call).with(error, env, response)
      end
    end
  end
end
