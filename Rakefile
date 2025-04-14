# frozen_string_literal: true

namespace :pb do
  desc "Install MacOS dependencies to generate protobuf files"
  task :install do
    sh "brew install protobuf"
    sh "brew install protoc-gen-go"
  end

  desc "Generate protobuf files for Ruby and Go"
  task :generate do
    sh "protoc -I=. --ruby_out=ruby/lib/umbra/pb --go_out=pb --go_opt=paths=source_relative ./umbra.proto"
  end
end

desc "Build the umbra shadower binary for the local arch"
task :build do
  sh "go build -v ."
end
