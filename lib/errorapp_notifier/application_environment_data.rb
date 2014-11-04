class ApplicationEnvironmentData
  attr_reader :exception

  def initialize(exception)
    @exception = exception
  end

  def data
    {
      :application_environment =>
      {
        :environment => application_environment,
        :env => extract_environment(ENV),
        :host => get_hostname,
        :run_as_user => get_username,
        :application_root_directory => application_root_directory,
        :language => 'ruby',
        :language_version => language_version_string,
        :libraries_loaded => libraries_loaded
      }
    }
  end

  private

  def application_root_directory
    (application_root.to_s.respond_to?(:force_encoding) ?
     application_root.to_s.force_encoding("UTF-8") : application_root)
  end

  def application_environment
    config.application_environment
  end

  def application_root
    config.application_root
  end

  def config
    ErrorappNotifier.configuration
  end

  def extract_environment(env)
    env.reject do |k, v|
      is_http_header = (k =~ /^HTTP_/)
      is_filtered = ErrorappNotifier::ENVIRONMENT_FILTER.include?(k)
      matches_whitelist = ErrorappNotifier::ENVIRONMENT_WHITELIST.
        any? do |whitelist_filter|
        whitelist_filter === k
      end
      is_http_header || is_filtered || !matches_whitelist
    end
  end

  def get_hostname
    require 'socket' unless defined?(Socket)
    Socket.gethostname
  rescue
    'UNKNOWN'
  end

  def get_username
    ENV['LOGNAME'] || ENV['USER'] || ENV['USERNAME'] || ENV['APACHE_RUN_USER'] || 'UNKNOWN'
  end

  def language_version_string
    "#{RUBY_VERSION rescue '?.?.?'} p#{RUBY_PATCHLEVEL rescue '???'} #{RUBY_RELEASE_DATE rescue '????-??-??'} #{RUBY_PLATFORM rescue '????'}"
  end

  def libraries_loaded
    begin
      return Hash[*Gem.loaded_specs.map{|name, gem_specification| [name, gem_specification.version.to_s]}.flatten]
    rescue
    end
    {}
  end
end
