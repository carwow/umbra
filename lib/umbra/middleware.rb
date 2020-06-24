module Umbra
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      Umbra.publish(env.dup)

      @app.call(env)
    end
  end
end
