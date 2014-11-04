module ErrorappNotifier
  module Integration
    class OmgTestException < StandardError;
    end

    def self.test
      begin
        raise OmgTestException.new, 'Test exception'
      rescue Exception => e
        ErrorappNotifier::Notifier.notify_error(
          ErrorappNotifier::FailureData.new(e, "Test Exception")
        )
      end
    end
  end
end
