require 'rails'
require 'errorapp_notifier'
require 'errorapp_notifier/notifiers/rack_rails'

module ErrorappNotifier
  class Railtie < Rails::Railtie
     rake_tasks do
      load "errorapp_notifier/tasks/errorapp_notifier.rake"
    end

    config.after_initialize do
      ErrorappNotifier.configure do |config|
        config.logger           ||= ::Rails.logger
        config.environment_name ||= ::Rails.env
        config.project_root     ||= ::Rails.root
        config.params_filters += Rails.configuration.filter_parameters.map do |filter|
          case filter
          when String, Symbol
            /\A#{filter}\z/
          else
            filter
          end
        end
      end
    end

    initializer "errorapp.middleware" do |app|
      if defined?(ActionController::Base)
        ActionController::Base.send(:include, ErrorappNotifier::ActionControllerMethods)
      end

      ErrorappNotifier.logger.info("Loading ErrorappNotifier #{ErrorappNotifier::VERSION} for #{Rails::VERSION::STRING}")

      middleware = if defined?(ActionDispatch::DebugExceptions)
                     # rails 3.2.x
                     "ActionDispatch::DebugExceptions"
                   elsif defined?(ActionDispatch::ShowExceptions)
                     # rails 3.0.x && 3.1.x
                     "ActionDispatch::ShowExceptions"
                   end
      begin
        app.config.middleware.insert_after middleware, "Rack::RailsErrorappNotifier"
      rescue
        app.config.middleware.use "Rack::RailsErrorappNotifier"
      end
    end
  end
end
