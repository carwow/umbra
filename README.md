# umbra :waning_crescent_moon:
### A shadow requesting tool for rack-based apps

`umbra` is a rack middleware that allows you to create shadow requests via a redis pub/sub channel.

This can help you to build confidence in your infrasture by simulating elevated traffic in a controlled manner. Thereby allowing you to observe and monitor the limits of your systems.

# Installation

Add this to your `Gemfile`

```ruby
gem 'umbra-rb'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install umbra-rb


## Usage

A minimal rack application using `umbra` would look like this:

```ruby
# /config.ru
require 'rack'
require 'rack/lobster'
require 'umbra'

Umbra.configure

use Umbra::Middleware
run Rack::Lobster.new

```

If using Rails you can achieve the same via an initializer:

```ruby
# /config/initializers/umbra.rb
require 'umbra'

Umbra.configure

Rails.application.config.middleware.use(Umbra::Middleware)
```

Then, in another process, you can start receiving each request via an `Umbra::Subscriber`.
`Umbra::Subscriber` can be initialized with anything response to `.call`. For example:

```ruby
Umbra::Subscriber.new(
  proc { |payload| puts "New Request: #{payload}" }
).start
```

The `payload` is the encoded request and response, as defined by the configured encoder. By default, this is `Umbra::Encoder`.

`umbra` also provides some helper classes for common use cases:

- `Umbra::RequestBuilder` takes the default encoding and returns a `Typhoeus::Request` object.
- `Umbra::ShadowRequester` can be configured to shadow requests `count:` times using a `pool:` of threads via a thread queue.
- More to come...


# Config

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/carwow/umbra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
