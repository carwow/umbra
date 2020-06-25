# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

namespace :pb do
  desc "Generate protobuf files for ruby and go"
  task :generate do
    `protoc -I=. --ruby_out=lib/umbra/pb --go_out=pb --go_opt=paths=source_relative ./umbra.proto`
  end
end

task :gobuild do
    `go build -o exe/umbra .`
end

task :gobuildall do
  oses = %w[linux darwin]
  platforms = %w[amd64]

  oses.product(platforms).each do |os, plat|
    puts " * Building umbra.#{plat}.#{os}"
    `GOOS=#{os} GOARCH=#{plat} go build -o exe/umbra.#{plat}.#{os} .`
  end
end
