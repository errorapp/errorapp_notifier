module ErrorappNotifier
  module ActionControllerMethods
    def rescue_with_errorapp(exception)
      unless exception_handled_by_rescue_from?(exception)
        notify_with_controller(exception)
        ErrorappNotifier.context.clear!
      end
    end

    def errorapp_rescue(context=nil, &block)
      begin
        ErrorappNotifier.context(context) unless context.nil?
        block.call
      rescue Exception => exception
        notify_with_controller(exception)
      ensure
        ErrorappNotifier.context.clear!
      end
    end

    private

    def notify_with_controller(exception)
      ErrorappNotifier::Notify.notify_with_controller(
        exception,
        self,
        request
      )
    end

    def exception_handled_by_rescue_from?(exception)
      respond_to?(:handler_for_rescue) && handler_for_rescue(exception)
    end
  end
end
