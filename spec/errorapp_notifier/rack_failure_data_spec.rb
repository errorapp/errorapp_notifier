require 'spec_helper'
require 'rack'
require 'time'

describe ErrorappNotifier::RackFailureData do

  class ErrorappNotifier::OmgError < StandardError
    def backtrace
      ['omg-backtrace']
    end
  end

  before :each do
    app = lambda { |env| [200, {'Content-Type'=>'text/plain'}, 'Hello World']}

    @env = {
      "HTTP_HOST" =>"localhost:4242",
      "HTTP_ACCEPT" =>"*/*",
      "SERVER_NAME" =>"localhost",
      "REQUEST_PATH" =>"/",
      "rack.url_scheme" =>"http",
      "HTTP_USER_AGENT" =>"curl/7.19.6 (i386-apple-darwin9.8.0) libcurl/7.19.6 zlib/1.2.3",
      "REMOTE_HOST" =>"testing.com",
      "rack.errors" => StringIO.new,
      "SERVER_PROTOCOL" =>"HTTP/1.1",
      "rack.version" =>[1, 1],
      "rack.run_once" =>false,
      "SERVER_SOFTWARE" =>"WEBrick/1.3.1 (Ruby/1.8.7/2009-06-12)",
      "REMOTE_ADDR" =>"127.0.0.1",
      "PATH_INFO" => "/",
      "SCRIPT_NAME" =>"",
      "HTTP_VERSION" =>"HTTP/1.1",
      "rack.multithread" =>true,
      "rack.multiprocess" =>false,
      "REQUEST_URI" =>"http://localhost:4242/",
      "SERVER_PORT" =>"4242",
      "REQUEST_METHOD" =>"GET",
      "rack.input" => StringIO.new,
      "QUERY_STRING" =>"cockle=shell&bay=cool",
      "GATEWAY_INTERFACE" =>"CGI/1.1"
    }

    error = ErrorappNotifier::OmgError.new('some message')
    request = Rack::Request.new(@env)
    @data = ErrorappNotifier::RackFailureData.new(error, @env, request)
  end

  it "capture exception details" do
    error_hash = @data.to_hash[:exception]
    error_hash[:exception_class].should == 'ErrorappNotifier::OmgError'
    error_hash[:message].should == 'some message'
    error_hash[:backtrace].should == ['omg-backtrace']
    DateTime.parse(error_hash[:occurred_at]).should == DateTime.parse(Time.now.to_s)
  end

  it "should capture request details" do
    request_hash = @data.to_hash[:request]
    request_hash[:url].should == 'http://localhost:4242/?cockle=shell&bay=cool'
    request_hash[:parameters].should == {"cockle"=>"shell", "bay"=>"cool"}
    request_hash[:request_method].should == 'GET'
    request_hash[:remote_ip].should == '127.0.0.1'
    request_hash[:headers].should == {"Host"=>"localhost:4242", "Accept"=>"*/*", "User-Agent"=>"curl/7.19.6 (i386-apple-darwin9.8.0) libcurl/7.19.6 zlib/1.2.3", "Version"=>"HTTP/1.1"}
    request_hash[:session].should == {'data' => {}, 'session_id' => ''}
  end

  it "should capture client detais" do
    client_hash = @data.to_hash[:client]
    client_hash[:name].should == 'errorapp_notifier-gem'
    client_hash[:version].should == ErrorappNotifier::VERSION
    client_hash[:protocol_version].should == 1
  end

  it "should captire application environment" do
    env_hash = @data.to_hash[:application_environment]
    env_hash[:env].should_not be_empty
    env_hash[:libraries_loaded].should_not be_empty
    env_hash[:language].should == 'ruby'

    env_hash[:language_version].should_not be_empty
    env_hash[:environment].should == 'test'
    env_hash[:application_root_directory].should_not be_empty
    env_hash[:run_as_user].should_not be_empty
    env_hash[:host].should_not be_empty
  end

end

