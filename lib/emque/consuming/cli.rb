require "optparse"
require "emque/consuming"
require "emque/consuming/generators/application"

module Emque
  module Consuming
    class Cli
      APP_CONFIG_FILE = "config/application.rb"
      COMMANDS = [:console, :new, :start, :stop]
      IP_REGEX = /^(\d{1,3}\.){3}\d{1,3}$/

      attr_reader :options

      def initialize(argv)
        self.argv = argv

        extract_command
        intercept_help

        load_app
        setup_options
        parse_options

        execute
      end

      private

      attr_reader :parser, :command
      attr_accessor :argv, :runner

      def execute
        if command == :new
          Emque::Consuming::Generators::Application.new(options, argv.last).generate
        else
          self.runner = Emque::Consuming::Runner.new(options)
          runner.send(command)
        end
      end

      def extract_command
        if argv.size > 1 and argv[-2] == "new"
          @command = :new
        elsif argv.size > 0
          @command = argv[-1].to_sym
        end
      end

      def intercept_help
        if command == :new and argv.last.to_sym == command
          argv << "--help"
        elsif ! COMMANDS.include?(command)
          argv << "--help"
        end
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

        @parser = OptionParser.new { |o|
          o.on("-P", "--pidfile PATH", "Store pid in PATH") do |arg|
            options[:pidfile] = arg
          end

          o.on(
            "-S",
            "--socket PATH",
            "PATH to the application's unix socket"
          ) do |arg|
            options[:socket_path] = arg
          end

          o.on(
            "-b",
            "--bind IP:PORT",
            "IP & port for the http status application to listen on."
          ) do |arg|
            ip, port = arg.split(":")
            port = port.to_i
            options[:status_host] = ip if ip =~ IP_REGEX
            options[:status_port] = port if port > 0 && port <= 65535
          end

          o.on("-d", "--daemon", "Daemonize the application") do
            options[:daemon] = true
          end

          o.on("-s", "--status", "Run the http status application") do
            options[:status] = :on
          end

          o.on("--app-name NAME", "Run the application as NAME") do |arg|
            options[:app_name] = arg
          end

          o.on(
            "--env (ex. production)",
            "Set the application environment, overrides EMQUE_ENV"
          ) do |arg|
            options[:env] = arg
          end

          o.banner = "emque <options> (start|stop|new|console|help) <name (new only)>"
        }
      end
    end
  end
end
