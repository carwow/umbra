# frozen_string_literal: true

RSpec.describe Umbra::Encoder do
  describe ".call" do
    let(:env) do
      {
        Rack::HTTPS => "on",
        Rack::SERVER_NAME => "umbra.local",
        Rack::PATH_INFO => "/path",
        Rack::QUERY_STRING => "param=1",
        Rack::REQUEST_METHOD => "GET",
        "HTTP_X_TEST" => "true",
        "umbra.request_body" => "x=y"
      }
    end

    subject(:result) { described_class.call(env) }

    let(:expected_message) do
      Umbra::Pb::Message.new(
        method: "GET",
        url: "https://umbra.local/path?param=1",
        body: "x=y",
        headers: {"x-umbra-request" => "true", "x-test" => "true"}
      )
    end

    it "returns the encoded protobuf string" do
      expect(result).to eq(expected_message.to_proto)
    end
  end
end
