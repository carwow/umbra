# frozen_string_literal: true

namespace :pb do
  desc "Generate protobuf files for ruby and go"
  task :generate do
    `protoc -I=. --ruby_out=ruby/lib/umbra/pb --go_out=pb --go_opt=paths=source_relative ./umbra.proto`
  end
end

desc "build the umbra shadower binary for the local arch"
task :gobuild do
  `go build -o exe/umbra .`
end

desc "build the umbra shadower binary for a matrix of arches"
task :gobuildall do
  oses = %w[linux darwin]
  platforms = %w[amd64]

  oses.product(platforms).each do |os, plat|
    puts " * Building umbra.#{plat}.#{os}"
    `GOOS=#{os} GOARCH=#{plat} go build -o exe/umbra.#{plat}.#{os} .`
  end
end
