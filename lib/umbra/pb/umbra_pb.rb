# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: umbra.proto

require "google/protobuf"

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_file("umbra.proto", syntax: :proto3) do
    add_message "umbra.pb.Message" do
      optional :method, :string, 1
      optional :url, :string, 2
      map :headers, :string, :string, 3
      optional :body, :bytes, 4
    end
  end
end

module Umbra
  module Pb
    Message = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("umbra.pb.Message").msgclass
  end
end
