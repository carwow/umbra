# umbra :waning_crescent_moon:

> **umbra** /ˈʌmbrə/
>
> noun
> 1. the fully shaded inner region of a shadow cast by an opaque object, especially the area on the earth or moon experiencing the total phase of an eclipse.
> 2. shadow or darkness.
>   "an impenetrable umbra seemed to fill every inch of the museum"

`umbra` is a rack middleware that allows you to create shadow requests via a redis pub/sub channel.

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
