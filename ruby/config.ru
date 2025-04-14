lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "rack"
require "rackup/lobster"
require "umbra"

Umbra.configure

use Umbra::Middleware
run Rackup::Lobster.new
