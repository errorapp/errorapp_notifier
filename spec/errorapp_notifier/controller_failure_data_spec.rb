require 'spec_helper'

describe ErrorappNotifier::ControllerFailureData do

  class ErrorappNotifier::OmgError < StandardError
    def backtrace
      ['omg-backtrace']
    end
  end

  class BrokenJSON
    def to_json
      omg
    end
  end

  it "parses session data" do
    request = ActionDispatch::TestRequest.new
    brokenJson = BrokenJSON.new
    session = {:foo  => brokenJson}
    request.stub(:session).and_return(session)
    data = ErrorappNotifier::ControllerFailureData.new(ErrorappNotifier::OmgError.new, nil, request)

    JSON.parse(data.to_json)['request']['session']['data'].should == {'foo' => brokenJson.to_s}
  end

  it "raises useful error when to_json isn't available on to_hash" do
    data = ErrorappNotifier::FailureData.new(ErrorappNotifier::OmgError.new)
    hash_without_json = {}
    hash_without_json.stub(:to_json).and_raise(NoMethodError)
    data.stub(:to_hash).and_return(hash_without_json)
    expect { data.to_json }.to raise_exception(/to_json/)
  end

  describe 'when no request/controller/params' do
    before do
      ENV['LOGNAME'] = 'bob'
      ENV['SOMETHING_SECRET'] = 'secretPasswords'
      ENV['DATABASE_URL'] = 'something'
      ENV['SOMETHING_INTERESTING'] = 'instagram'
      ENV['HTTP_SOMETHING'] = 'should be stripped'
      ENV['FILTERED_BY_OLD_FILTER_CONFIG'] = 'should_be_filtered'
      ErrorappNotifier::ENVIRONMENT_WHITELIST << /_INTERESTING/
        ErrorappNotifier::ENVIRONMENT_WHITELIST << 'FILTERED_BY_OLD_FILTER_CONFIG'
      ErrorappNotifier::ENVIRONMENT_FILTER << 'FILTERED_BY_OLD_FILTER_CONFIG'
      RAILS_ENV = 'test' unless defined?(RAILS_ENV)
      @occured_at = Time.mktime(1970, 1, 1)
      Time.stub(:now).and_return(Time.mktime(1970, 1, 1))
      error = ErrorappNotifier::OmgError.new('some message')
      @data = ErrorappNotifier::ControllerFailureData.new(error)
      @hash = @data.to_hash
    end

    it "capture exception details" do
      error_hash = @hash[:exception]
      error_hash[:exception_class].should == 'ErrorappNotifier::OmgError'
      error_hash[:message].should == 'some message'
      error_hash[:backtrace].should == ['omg-backtrace']
      DateTime.parse(error_hash[:occurred_at]).should == @occured_at
      client_hash = @hash[:client]
      client_hash[:name].should == ErrorappNotifier::CLIENT_NAME
      client_hash[:version].should == ErrorappNotifier::VERSION
      client_hash[:protocol_version].should == ErrorappNotifier::PROTOCOL_VERSION
    end


    it "has sensible initial ENVIRONMENT_WHITELIST" do
      %w(HOME PATH PWD RUBYOPT GEM_HOME RACK_ENV RAILS_ENV BUNDLE_GEMFILE BUNDLE_BIN_PATH).each do |expected_to_be_whitelisted|
        ErrorappNotifier::ENVIRONMENT_WHITELIST.should include(expected_to_be_whitelisted)
      end
    end

    it "uses a whitelist for ENV variables aswell as existing filter" do
      env = @hash[:application_environment][:env]
      env['SOMETHING_SECRET'].should be_nil
      env['DATABASE_URL'].should be_nil
      env['HTTP_SOMETHING'].should be_nil
      env['FILTERED_BY_OLD_FILTER_CONFIG'].should be_nil
      env['SOMETHING_INTERESTING'].should == 'instagram'
    end

    it "generates parseable json" do
      require 'json'
      JSON.parse(@data.to_json)['exception']['exception_class'].should == 'ErrorappNotifier::OmgError'
    end

    it "capture application_environment" do
      application_env_hash = @hash[:application_environment]
      application_env_hash[:environment].should == 'test'
      application_env_hash[:env].should_not be_nil
      application_env_hash[:host].should == `hostname`.strip
      application_env_hash[:run_as_user].should == 'bob'
      application_env_hash[:application_root_directory].should == Dir.pwd
      application_env_hash[:language].should == 'ruby'
      application_env_hash[:language_version].should == "#{RUBY_VERSION} p#{RUBY_PATCHLEVEL} #{RUBY_RELEASE_DATE} #{RUBY_PLATFORM}"
      application_env_hash[:libraries_loaded]['rspec'].should == '2.14.0'
    end
  end

  describe 'with request/controller/params' do

    class ErrorappNotifier::SomeController
    end

    before :each do
      @controller = ErrorappNotifier::SomeController.new
      @request = ActionDispatch::TestRequest.new
      @request.stub(:parameters).and_return({'var1' => 'abc', 'action' => 'some_action', 'filter_me' => 'private'})
      @request.stub(:url).and_return('http://youtube.com/watch?v=oHg5SJYRHA0')
      @request.stub(:request_method).and_return(:get)
      @request.stub(:remote_ip).and_return('1.2.3.4')
      @request.stub(:env).and_return({'SOME_VAR' => 'abc', 'HTTP_CONTENT_TYPE' => 'text/html'})
      @request.env["action_dispatch.parameter_filter"] = [:filter_me]
      @error = ErrorappNotifier::OmgError.new('some message')
      data = ErrorappNotifier::ControllerFailureData.new(@error, @controller, @request)
      @hash = data.to_hash
    end

    it "captures request" do
      request_hash = @hash[:request]
      request_hash[:url].should == 'http://youtube.com/watch?v=oHg5SJYRHA0'
      request_hash[:controller].should == 'ErrorappNotifier::SomeController'
      request_hash[:action].should == 'some_action'
      request_hash[:parameters].should == {'var1' => 'abc', 'action' => 'some_action', 'filter_me' => '[FILTERED]'}
      request_hash[:request_method].should == 'get'
      request_hash[:remote_ip].should == '1.2.3.4'
      request_hash[:headers].should == {'Content-Type' => 'text/html'}
    end


    it "filter params specified in env['action_dispatch.parameter_filter']" do
      @request.stub(:env).and_return({'SOME_VAR' => 'abc', 'HTTP_CONTENT_TYPE' => 'text/html', 'action_dispatch.parameter_filter' => [:var1]})
      @request.stub(:parameters).and_return({'var1' => 'abc'})
      data = ErrorappNotifier::ControllerFailureData.new(@error, @controller, @request)
      data.to_hash[:request][:parameters].should == {'var1' => '[FILTERED]'}
    end

    it "filter nested params specified in env['action_dispatch.parameter_filter']" do
      @request.stub(:env).and_return({'SOME_VAR' => 'abc', 'HTTP_CONTENT_TYPE' => 'text/html', 'action_dispatch.parameter_filter' => [:var1]})
      @request.stub(:parameters).and_return({'var1' => {'var2' => 'abc','var3' => "abc"}})
      data = ErrorappNotifier::ControllerFailureData.new(@error, @controller, @request)
      data.to_hash[:request][:parameters].should == {'var1' => '[FILTERED]'}
    end

    it "formats the occurred_at as iso8601" do
      @request.stub(:env).and_return({'SOME_VAR' => 'abc', 'HTTP_CONTENT_TYPE' => 'text/html', 'action_dispatch.parameter_filter' => [:var1]})
      @request.stub(:parameters).and_return({'var1' => 'abc'})
      data = ErrorappNotifier::ControllerFailureData.new(@error, @controller, @request)
      data.to_hash[:exception][:occurred_at].should match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.{1,6}$/)
    end

    it "filter session cookies from headers" do
      @request.stub(:env).and_return({'SOME_VAR' => 'abc', 'HTTP_COOKIE' => '_something_else=faafsafafasfa; _myapp-lick-nation_session=BAh7DDoMbnVtYmVyc1sJaQZpB2kIaQk6FnNvbWVfY3Jhenlfb2JqZWN0bzobU3Bpa2VDb250cm9sbGVyOjpDcmF6eQY6CUBiYXJABzoTc29tZXRoaW5nX2Vsc2UiCGNjYzoKYXBwbGUiDUJyYWVidXJuOgloYXNoewdpBmkHaQhpCToPc2Vzc2lvbl9pZCIlMmJjZTM4MjVjMThkNzYxOWEyZDA4NTJhNWY1NGQzMmU6C3RvbWF0byIJQmVlZg%3D%3D--66fb4606851f06bf409b8bc4ba7aea47f0259bf7'})
      @hash = ErrorappNotifier::ControllerFailureData.new(ErrorappNotifier::OmgError.new('some message'), @controller, @request).to_hash
      @hash[:request][:headers].should == {'Cookie' => '_something_else=faafsafafasfa; _myapp-lick-nation_session=[FILTERED]'}
    end

    it "creates a uniq_key from backtrace" do
      exception = Exception.new
      exception.stub(:backtrace).and_return(['123'])
      data = ErrorappNotifier::ControllerFailureData.new(exception)
      data.uniq_key.should == Digest::MD5.hexdigest('123')
    end

    it "creates a nil uniq_key if nil backtrace" do
      exception = Exception.new
      exception.stub(:backtrace).and_return(nil)
      data = ErrorappNotifier::ControllerFailureData.new(exception)
      data.uniq_key.should == nil
    end

    it "creates a uniq_key from backtrace" do
      exception = Exception.new
      exception.stub(:backtrace).and_return([])
      data = ErrorappNotifier::ControllerFailureData.new(exception)
      data.uniq_key.should == nil
    end
  end
end

describe ErrorappNotifier::ControllerDataExtractor do
  before do
    @request = double(
      :protocol    => "http://",
      :host        => "errorapp",
      :request_uri => "/projects",
      :params =>
      {
        "action" => "index",
        "controller" => "projects",
        "foo"        => "bar"
      },
        :request_method => "GET",
        :ip             => "1.2.3.4",
        :env            => "fuzzy"
    )
    @controller = "Controller"
  end

  subject { ErrorappNotifier::ControllerDataExtractor.new(@controller, @request) }

  it "should extract the controller class" do
    subject.controller.should == "String"
  end

  it "should extract the URL" do
    subject.url.should == "http://errorapp/projects"
  end

  it "should extract action" do
    subject.action.should == "index"
  end

  it "should extract parameters" do
    subject.parameters.should == {
      "action" => "index",
      "controller" => "projects",
      "foo" => "bar"
    }
  end

  it "should extract request method" do
    subject.request_method.should == "GET"
  end

  it "should extract remote ip" do
    subject.remote_ip.should == "1.2.3.4"
  end

  it "should extract env" do
    subject.env.should == "fuzzy"
  end

  it "should make request available" do
    subject.request.should == @request
  end

  context "with params available in request" do
    before do
      @request = double(
        :url    => "http://errorapp/projects",
        :parameters =>
        {
          "action" => "index",
          "controller" => "projects",
          "foo"        => "bar"
        },
          :request_method => "GET",
          :remote_ip      => "1.2.3.4",
          :env            => "fuzzy"
      )
      @controller = "Controller"
    end

    subject { ErrorappNotifier::ControllerDataExtractor.new(@controller, @request) }

    it "should extract the URL" do
      subject.url.should == "http://errorapp/projects"
    end

    it "should extract action" do
      subject.action.should == "index"
    end

    it "should extract parameters" do
      subject.parameters.should == {
        "action" => "index",
        "controller" => "projects",
        "foo" => "bar"
      }
    end

    it "should extract remote ip" do
      subject.remote_ip.should == "1.2.3.4"
    end
  end
end
