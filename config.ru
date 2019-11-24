require 'rack'
require 'rack/lobster'
require 'umbra'

Umbra.configure

use Umbra::Middleware
run Rack::Lobster.new
