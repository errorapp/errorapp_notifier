require 'logger'

require 'errorapp_notifier/config'
require 'errorapp_notifier/failure_data'
require 'errorapp_notifier/notify'
require 'errorapp_notifier/controller_failure_data'
require 'errorapp_notifier/rack_failure_data'
require 'errorapp_notifier/notifier'
require 'errorapp_notifier/sanitizer'
require 'errorapp_notifier/version'
require 'errorapp_notifier/action_controller_methods'
require 'errorapp_notifier/notifiers/tester'

require 'errorapp_notifier/railtie' if defined?(Rails::Railtie)

module ErrorappNotifier
  PROTOCOL_VERSION = 1
  CLIENT_NAME = 'errorapp_notifier-gem'
  ENVIRONMENT_FILTER = []
  ENVIRONMENT_WHITELIST = %w(HOME PATH PWD RUBYOPT GEM_HOME RACK_ENV
                             RAILS_ENV BUNDLE_GEMFILE BUNDLE_BIN_PATH)


 class << self
   def configure
     yield(configuration)
   end

   def configuration
     @configuration ||= ErrorappNotifier::Config.new
   end

   def logger
     configuration.logger
   end

   def notify(exception, name=nil)
     ErrorappNotifier::Notify.notify(exception, name)
   end

   def rescue(name=nil, context=nil, &block)
     begin
       context(context) unless context.nil?
       block.call
     rescue Exception => e
       ErrorappNotifier::Notify.notify(e, name)
     ensure
       clear!
     end
   end

   def rescue_and_reraise(name=nil, context=nil, &block)
     begin
       context(context) unless context.nil?
       block.call
     rescue Exception => e
       ErrorappNotifier::Notify.notify(e, name)
       raise(e)
     ensure
       clear!
     end
   end

   def clear!
     Thread.current[:notifier_context] = nil
   end

   def context(hash = {})
     Thread.current[:notifier_context] ||= {}
     Thread.current[:notifier_context].merge!(hash)
     self
   end
 end
end
