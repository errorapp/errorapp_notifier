require 'spec_helper'

describe ErrorappNotifier::Config, 'defaults' do
  it "have sensible defaults" do
    default_config.ssl.should == true
    default_config.remote_host.should == 'errorapp.com'
    default_config.remote_port.should == 443
    default_config.application_root.should == Dir.pwd
    default_config.http_proxy_host.should be_nil
    default_config.http_proxy_port.should be_nil
    default_config.http_proxy_username.should be_nil
    default_config.http_proxy_password.should be_nil
    default_config.http_open_timeout.should == 2
    default_config.http_read_timeout.should == 4
  end

  it "have correct defaults when ssl" do
    default_config.ssl = true
    default_config.remote_host.should == 'errorapp.com'
    default_config.remote_port.should == 443
  end

  it "be disabled based on environment by default" do
    %w(development test).each do |env|
      default_config.stub(:application_environment).and_return(env)
      default_config.should_send_to_api?.should == false
    end
  end

  it "be enabled based on environment by default" do
    %w(production staging).each do |env|
      default_config.stub(:application_environment).and_return(env)
      default_config.should_send_to_api?.should == true
    end
  end

  it "load api_key from environment variable" do
    ENV.stub(:[]).with('ERRORAPP_API_KEY').and_return('env-api-key')
    default_config.api_key.should == 'env-api-key'
  end

  context 'production environment' do
    before :each do
      default_config.stub(:application_environment).and_return('production')
    end

    it 'loads a errorapp_notifier config' do
      override_default_value :api_key
      override_default_value :ssl, true
      override_default_value :remote_host, 'example.com'
      override_default_value :remote_port, 3000
      override_default_value :http_proxy_host, 'annoying-proxy.example.com'
      override_default_value :http_proxy_port, 1066
      override_default_value :http_proxy_username, 'username'
      override_default_value :http_proxy_password, 'password'
      override_default_value :http_open_timeout, 5
      override_default_value :http_read_timeout, 10
    end

    it 'disable' do
      default_config.api_key = "new-key"
      default_config.disabled_by_default = %(production)
      default_config.api_key.should == 'new-key'
      default_config.should_send_to_api?.should == false
    end
  end
end

def default_config
  @config||= ErrorappNotifier::Config.new
end

def override_default_value(option, value ="value")
  default_config.send(:"#{option}=", value)
  expect(default_config.send(option)).to eq(value)
end
