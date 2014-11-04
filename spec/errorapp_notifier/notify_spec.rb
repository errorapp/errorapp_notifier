require 'spec_helper'

describe ErrorappNotifier::Notify do
  describe "when ErrorappNotifier reporting is on" do

    before do
      @config = ErrorappNotifier::configuration
      @config.stub(:should_send_to_api?).and_return(true)
      @config.ignore_user_agents = []
    end

    describe "#notify" do
      it "should create FailureData object and send json to the api" do
        exception = double("exception")
        name = double("name")
        args = [exception, name]
        data = double("data")

        ErrorappNotifier::FailureData.should_receive(:new).with(*args).and_return(data)
        ErrorappNotifier::Notifier.should_receive(:notify_error).with(data)
        ErrorappNotifier::Notify.notify(*args)
      end
    end

    describe "#notify_with_controller" do
      it "should create ControllerFailureData object and send json to the api" do
        exception = double('exception')
        controller = double('controller')
        request = double('request')
        args = [exception, controller, request]
        data = double("data")

        ErrorappNotifier::ControllerFailureData.should_receive(:new).with(*args).and_return(data)
        ErrorappNotifier::Notifier.should_receive(:notify_error).with(data)
        ErrorappNotifier::Notify.notify_with_controller(*args)
      end
    end

    describe "#notify_with_rack" do
      it "should create RackFailureData object and send json to the api" do
        exception = double("exception")
        environment = double("environment")
        request = double("request")
        args = [exception, environment, request]
        data = double("data")

        ErrorappNotifier::RackFailureData.should_receive(:new).with(*args).and_return(data)
        ErrorappNotifier::Notifier.should_receive(:notify_error).with(data)
        ErrorappNotifier::Notify.notify_with_rack(*args)
      end
    end

    describe "#ignore?" do

      before do
        @exception = double('exception')
        @controller = double('controller')
        @request = double('request')
      end

      it "should check for ignored classes and agents" do
        ErrorappNotifier::Notify.should_receive(:ignore_class?).with(@exception)
        ErrorappNotifier::Notify.should_receive(:ignore_user_agent?).with(@request)
        ErrorappNotifier::ControllerFailureData.should_receive(:new).
          with(@exception,@controller,@request).
          and_return(data = double('data'))
        ErrorappNotifier::Notifier.should_receive(:notify_error).with(data)

        ErrorappNotifier::Notify.notify_with_controller(@exception,
                                                         @controller,
                                                         @request)
      end

      it "should ignore exceptions by class name" do
        request = double("request")
        exception = double("exception")
        exception.stub(:class).and_return("ignore_me")
        exception.should_receive(:class)

        @config.ignore_exceptions = ["ignore_me",/funky/]
        ErrorappNotifier::Notify.ignore_class?(exception).should be_true
        funky_exception = double("exception")
        funky_exception.stub(:class).and_return("really_funky_exception")
        funky_exception.should_receive(:class)

        ErrorappNotifier::Notify.ignore_class?(funky_exception).should be_true
      end

      it "should ignore exceptions by user agent" do
        request = double("request")
        request.stub(:user_agent).and_return("botmeister")
        request.should_receive(:user_agent)

        @config.ignore_user_agents = [/bot/]
        ErrorappNotifier::Notify.ignore_user_agent?(request).should be_true
      end

    end
  end

  describe "when ErrorappNotifier reporting is off" do

    before do
      ErrorappNotifier::Config.stub(:should_send_to_api?).and_return(false)
    end

    describe "#notify, #notify_with_controller and #notify_with_rack" do

      it "should reraise the exception and not report it" do
        exception = double('exception')
        controller = double('controller')
        request = double('request')

        ErrorappNotifier::ControllerFailureData.should_not_receive(:new)
        ErrorappNotifier::Notifier.should_not_receive(:notify_error)

        ["rails", "rack", ""].each do |notify|
          method_name = "notify"
          method_name << "_with_#{notify}" unless notify.empty?
          expect do
            ErrorappNotifier::Notify.send(method_name, exception, controller, request)
          end.to raise_exception
        end
      end
    end
  end
end

