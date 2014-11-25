module ErrorappNotifier
  class ControllerFailureData < FailureData
    def initialize(exception, controller = nil, request = nil)
      super(exception)
      @data = ControllerDataExtractor.new(controller, request) unless request.nil?
    end

    private

    def extra_stuff
      return {} if @data.nil?
      {
        :request =>
        {
          :url => @data.url,
          :controller => @data.controller,
          :action => @data.action,
          :parameters => @data.parameters,
          :request_method => @data.request_method,
          :remote_ip => @data.remote_ip,
          :headers => extract_http_headers(@data.env),
          :session => Sanitizer.sanitize_session(@data.request)
        }
      }
    end
  end

  class ControllerDataExtractor
    def initialize(controller, request)
      @request = request
      @controller = controller
    end

    def controller
      "#{@controller.class}"
    end

    def url
      if @request.respond_to?(:url)
        @request.url
      else
        "#{@request.protocol}#{@request.host}#{@request.request_uri}"
      end
    end

    def action
      parameters["action"]
    end

    def parameters
      parameters = if @request.respond_to?(:parameters)
                     @request.parameters
                   elsif action_dispatch_params
                    action_dispatch_params
                   else
                     @request.params
                   end

      filter_parameters(parameters)
    end

    def request_method
      "#{@request.request_method}"
    end

    def remote_ip
      if @request.respond_to?(:remote_ip)
        @request.remote_ip
      else
        @request.ip
      end
    end

    def env
      @request.env
    end

    def request
      @request
    end

    private

    def filter_parameters(hash)
      if @request.respond_to?(:env) && @request.env["action_dispatch.parameter_filter"]
        Sanitizer.filter_hash(@request.env["action_dispatch.parameter_filter"], hash)
      elsif @controller.respond_to?(:filter_parameters)
        @controller.send(:filter_parameters, hash)
      else
        hash
      end
    end

    def action_dispatch_params
       @request.env['action_dispatch.request.parameters']
    end
  end
end
