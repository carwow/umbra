module Umbra
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)

      Umbra.publish(env.dup, response.dup)

      response
    end
  end
end
