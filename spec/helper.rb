class TestException < StandardError
  attr_accessor :message, :backtrace

  def initialize(opts={})
    @message = opts[:message] || deafult_message
    @backtrace = opts[:backtrace]
  end

  def deafult_message
    "Something is not good"
  end
end
