require "logger"

module Emque
  module Consuming
    module Logging
      class LogFormatter < Logger::Formatter
        def call(severity, time, progname, msg)
          "#{time.utc} [#{severity}] #{msg}\n"
        end
      end

      def self.initialize_logger(log_target = STDOUT)
        @logger = Logger.new(log_target)
        @logger.level = Logger::INFO
        @logger.formatter = LogFormatter.new
        @logger
      end

      def self.logger
        defined?(@logger) ? @logger : initialize_logger
      end

      def self.logger=(log)
        @logger = log || Logger.new("/dev/null")
      end

      def logger
        Emque::Consuming::Logging.logger
      end
    end
  end
end
