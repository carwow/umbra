# frozen_string_literal: true

RSpec.describe Umbra::RequestBuilder do
  subject(:request) { described_class.call(env) }

  let(:query) { 'query_key_1=query_value1&query_key_2=query_value2' }
  let(:script_name) { '/script_name' }
  let(:path_info) { '/endpoint' }
  let(:headers) { { 'HTTP_USER_AGENT' => 'user', 'HTTP_HOST' => 'example.com' } }
  let(:host) { 'example.com' }
  let(:scheme) { 'https' }
  let(:method) { 'GET' }
  let(:body) { '' }
  let(:env) do
    {
      'request' => {
        'host' => host,
        'headers' => headers,
        'method' => method,
        'query' => query,
        'script_name' => script_name,
        'path_info' => path_info,
        'scheme' => scheme,
        'body' => body
      }
    }
  end

  let(:expected_options) do
    {
      method: :get,
      body: '',
      headers: include(
        'User-Agent' => 'user',
        'Host' => 'example.com',
        'Cache-Control' => 'no-cache, no-store, private, max-age=0',
        'X-Umbra-Request' => 'true'
      )
    }
  end

  let(:base_url) { "#{scheme}://#{host}#{script_name}#{path_info}?#{query}" }

  it { is_expected.to be_a(Typhoeus::Request) }
  it { expect(request.base_url).to eq(base_url) }
  it { expect(request.options).to include(expected_options) }
end
