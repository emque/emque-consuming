require "active_support/core_ext/string"
require "optparse"
require "emque/consuming"

module Emque
  module Consuming
    class Cli
      APP_CONFIG_FILE = "config/application.rb"
      COMMANDS = [:console, :start, :stop]
      IP_REGEX = /^(\d{1,3}\.){3}\d{1,3}$/

      attr_reader :options

      def initialize(argv)
        self.argv = argv
        self.command = argv.last.to_sym if argv.size > 0

        intercept_help

        load_app
        setup_options
        parse_options

        self.runner = Emque::Consuming::Runner.new(options)

        runner.send(command)
      end

      private

      attr_reader :parser
      attr_accessor :argv, :command, :runner

      def intercept_help
        argv << "--help" unless COMMANDS.include?(command)
      end

      def load_app
        current_dir = Dir.pwd

        if File.exist?(File.join(current_dir, APP_CONFIG_FILE))
          require_relative File.join(current_dir, APP_CONFIG_FILE)
        end
      end

      def parse_options
        parser.parse!(argv)
      end

      def setup_options
        @options = {
          :daemon => false
        }

        @parser = OptionParser.new do |o|
          o.on("-P", "--pidfile PATH", "Store pid in PATH") do |arg|
            options[:pidfile] = arg
          end

          o.on(
            "-S",
            "--socket PATH",
            "PATH to the service's unix socket"
          ) do |arg|
            @options[:socket_path] = arg
          end

          o.on(
            "-b",
            "--bind IP:PORT",
            "IP & port for the http status service to listen on."
          ) do |arg|
            ip, port = arg.split(":")
            port = port.to_i
            @options[:status_host] = ip if ip =~ IP_REGEX
            @options[:status_port] = port if port > 0 && port <= 65535
          end

          o.on("-d", "--daemon", "Daemonize the service") do
            options[:daemon] = true
          end

          o.on(
            "-e",
            "--error-limit N",
            "Set the max errors before service suicide"
          ) do |arg|
            limit = arg.to_i
            @options[:error_limit] = limit if limit > 0
          end

          o.on("-s", "--status", "Run the http status service") do
            options[:status] = :on
          end

          o.on(
            "-x",
            "--error-expiration SECONDS",
            "Expire errors after SECONDS"
          ) do |arg|
            exp = arg.to_i
            @options[:error_expiration] = exp if exp > 0
          end

          o.on("--app-name NAME", "Run the application as NAME") do |arg|
            @options[:app_name] = arg
          end

          o.on(
            "--env (ex. production)",
            "Set the application environment, overrides EMQUE_ENV"
          ) do |arg|
            @options[:env] = arg
          end

          o.banner = "emque <options> (start|stop|console|help)"
        end
      end
    end
  end
end
