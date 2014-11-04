class ExceptionData
  attr_reader :exception

  def initialize(exception)
    @exception = exception
  end

  def data
    {
      :exception =>
      {
        :exception_class => exception.class.to_s,
        :message => exception.message,
        :backtrace => exception.backtrace,
        :occurred_at => Time.now.utc.iso8601
      }
    }
  end
end
