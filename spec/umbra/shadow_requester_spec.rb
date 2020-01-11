require 'spec_helper'

RSpec.describe Umbra::ShadowRequester do
  let(:count) { 10 }
  let(:instance) { described_class.new(count: count) }
  let(:env) do
    {
      'request' => {
        'method' => 'GET',
        'scheme' => 'http',
        'host' => 'www.example.com',
        'body' => '',
        'query' => '',
        'script_name' => '',
        'path_info' => '',
        'headers' => {}
      }
    }
  end

  describe '#call!' do
    it 'makes count requests' do
      stub_request(:get, 'www.example.com')

      instance.call!(env)

      expect(WebMock).to have_requested(:get, 'www.example.com').times(count)
    end
  end
end
