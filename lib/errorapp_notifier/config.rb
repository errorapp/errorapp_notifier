module ErrorappNotifier
  class Config
    attr_accessor :api_key
    attr_accessor :disabled_by_default
    attr_accessor :environment_name
    attr_accessor :http_open_timeout
    attr_accessor :http_proxy_host
    attr_accessor :http_proxy_password
    attr_accessor :http_proxy_port
    attr_accessor :http_proxy_username
    attr_accessor :http_read_timeout
    attr_accessor :ignore_exceptions
    attr_accessor :ignore_user_agents
    attr_accessor :logger
    attr_accessor :params_filters
    attr_accessor :project_root
    attr_accessor :remote_host
    attr_accessor :remote_port
    attr_accessor :ssl

    DEFAULT_IGNORE_EXCEPTIONS = ['ActiveRecord::RecordNotFound',
                                 'ActionController::RoutingError',
                                 'ActionController::InvalidAuthenticityToken',
                                 'CGI::Session::CookieStore::TamperedWithCookie',
                                 'ActionController::UnknownAction',
                                 'AbstractController::ActionNotFound',
                                 'ActionController::UnknownFormat',
                                 'Mongoid::Errors::DocumentNotFound',
                                 'Sinatra::NotFound',
                                 "SystemExit",
                                 "SignalException"].freeze

    DEFAULT_PARAMS_FILTERS = %w(password password_confirmation).freeze

    alias_method :ssl?, :ssl

    def initialize
      @api_key             = ENV['ERRORAPP_API_KEY']
      @disabled_by_default = %w(development test)
      @http_open_timeout   = 2
      @http_read_timeout   = 4
      @ignore_exceptions   = DEFAULT_IGNORE_EXCEPTIONS
      @ignore_user_agents  = []
      @logger              = Logger.new(STDOUT)
      @params_filters      = DEFAULT_PARAMS_FILTERS
      @remote_host         = "errorapp.com"
      @remote_port         = nil
      @ssl                 = true
    end

    def should_send_to_api?
      !disabled_by_default.include?(application_environment)
    end

    def application_root
      @project_root || Dir.pwd
    end

    def remote_port
      @remote_port ||= ssl? ? 443 : 80
    end

    def application_environment
      @environment_name || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
    end
  end
end
