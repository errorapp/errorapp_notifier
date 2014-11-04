require 'rack'

module Rack
  class RailsErrorappNotifier
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        body = @app.call(env)
      rescue Exception => e
        ::ErrorappNotifier::Notify.notify_with_controller(
          e,
          env['action_controller.instance'],
          Rack::Request.new(env)
        )
        raise
      end

      if env['rack.exception']
        ::ErrorappNotifier::Notify.notify_with_controller(
          env['rack.exception'],
          env['action_controller.instance'],
          Rack::Request.new(env)
        )
      end

      body
    end
  end
end
