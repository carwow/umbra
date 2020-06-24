# frozen_string_literal: true

RSpec.describe "Integration" do
  include Rack::Test::Methods

  class FakeRedis
    attr_reader :messages

    def initialize
      @messages = []
    end

    def ping
    end

    def publish(channel, message)
      @messages << [channel, message]
    end
  end

  def app
    Rack::Builder.parse_file("config.ru").first
  end

  before { allow(Umbra).to receive(:redis).and_return(redis) }

  let(:redis) { FakeRedis.new }

  it "returns OK" do
    get "/"

    expect(last_response).to be_ok
  end

  it "publishes to the redis channel" do
    get "/"

    sleep(0.1)

    expect(redis.messages.count).to eq(1)
  end

  fit "publishes the expected protobuf message" do
    post "/", "request-body"

    sleep(0.1)

    expect(redis.messages).to eq(
      [
        [
          Umbra::CHANNEL,
          Umbra::Pb::Message.new(
            method: "POST",
            url: "http://example.org/",
            body: "request-body",
            headers: {
              "host" => "example.org",
              "x-umbra-request" => "true",
              "cookie" => ""
            }
          ).to_proto
        ]
      ]
    )
  end
end
