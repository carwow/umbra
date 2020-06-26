lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rack"
require "rack/lobster"
require "puma"
require "umbra"
require "pry"

Umbra.configure

use Umbra::Middleware
run Rack::Lobster.new
