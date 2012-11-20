# encoding: utf-8
module Ripple
  module Loggable

    def logger
      return @logger if defined?(@logger)
      @logger = rails_logger || default_logger
    end

    def logger=(logger)
      @logger = logger
    end

  private

    def default_logger
      logger = Logger.new($stdout)
      logger.level = Logger::INFO
      logger
    end

    def rails_logger
      defined?(::Rails) && ::Rails.respond_to?(:logger) && ::Rails.logger
    end
  end
end
