require "logger"
require "json"

module Emque
  module Consuming
    module Logging
      def self.initialize_logger(log_target = STDOUT)
        @logger = Logger.new(log_target)
        @logger.level = Logger::INFO
        @logger
      end

      def self.logger
        defined?(@logger) ? @logger : initialize_logger
      end

      def self.logger=(log)
        @logger = log || Logger.new(STDOUT)
      end

      def logger
        Emque::Consuming::Logging.logger
      end

      class Logger < ::Logger
        def initialize(*args, **kwargs)
          super
          self.formatter = Formatters::StandardFormatter.new
        end

        module Formatters
          class StandardFormatter < ::Logger::Formatter
            def call(severity, time, progname, msg)
              "#{time.utc} [#{severity}] #{msg}\n"
            end
          end

          class JsonFormatter < ::Logger::Formatter
            def call(severity, time, progname, msg)
             JSON.dump({
               timestamp: time,
               level: severity,
               ddsource: "ruby",
               message: msg
             }) << "\n"
            end
          end
        end
      end
    end
  end
end
