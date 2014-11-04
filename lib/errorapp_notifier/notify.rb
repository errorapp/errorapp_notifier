module ErrorappNotifier
  class Notify
    class << self
      def notify_with_controller(exception, controller = nil, request = nil)
        notify_exception(exception) do
          if !ignore?(exception, request)
            ControllerFailureData.new(exception, controller, request)
          end
        end
      end

      def notify_with_rack(exception, environment, request)
        notify_exception(exception) do
          RackFailureData.new(exception, environment, request)
        end
      end

      def notify(exception, name = nil)
        notify_exception(exception) do
          FailureData.new(exception, name)
        end
      end

      def ignore?(exception, request)
        ignore_class?(exception) || ignore_user_agent?(request)
      end

      def ignore_class?(exception)
        config.ignore_exceptions.flatten.any? do |exception_class|
          exception_class === exception.class.to_s
        end
      end

      def ignore_user_agent?(request)
        config.ignore_user_agents.flatten.any? do |user_agent|
          user_agent === request.user_agent.to_s
        end
      end

      private

      def notify_exception(exception, &block)
        if config.should_send_to_api?
          notify!(yield)
        else
          raise exception
        end
      end

      def notify!(data)
        Notifier.notify_error(data)
      end

      def config
        ErrorappNotifier.configuration
      end
    end
  end
end
