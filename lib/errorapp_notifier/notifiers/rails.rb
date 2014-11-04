# force Rails < 2.0 to use quote keys as per the JSON standard...
if defined?(ActiveSupport) &&
    defined?(ActiveSupport::JSON) &&
    ActiveSupport::JSON.respond_to?(:unquote_hash_key_identifiers)
  ActiveSupport::JSON.unquote_hash_key_identifiers = false
end

if defined? ActionController
  module ActionController
    class Base
      def rescue_action_with_errorapp(exception)
        unless exception_handled_by_rescue_from?(exception)
          ErrorappNotifier::Notify.notify_with_controller(
            exception,
            self,
            request
          )
          ErrorappNotifier.context.clear!
        end
        rescue_action_without_errorapp exception
      end

      alias_method :rescue_action_without_errorapp, :rescue_action
      alias_method :rescue_action, :rescue_action_with_errorapp
      protected :rescue_action

      private

      def exception_handled_by_rescue_from?(exception)
        respond_to?(:handler_for_rescue) && handler_for_rescue(exception)
      end
    end
  end
end
