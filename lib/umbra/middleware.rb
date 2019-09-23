module Umbra
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      response = @app.call(env)

      Umbra.publish(env, response)

      response
    end
  end
end
