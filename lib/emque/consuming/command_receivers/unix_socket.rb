require "socket"
require "emque/consuming/command_receivers/base"

module Emque
  module Consuming
    module CommandReceivers
      class UnixSocket < Base

        def start
          @thread = new_socket_server
          status
        end

        private

        def app_name
          config.app_name.capitalize
        end

        def new_socket_server
          Thread.new {
            loop do
              Socket.unix_server_loop(config.socket_path) do |sock, client_addr|
                begin
                  receive_command(sock)
                rescue
                  # nothing to do but restart the socket
                ensure
                  sock.close
                end
              end
            end
          }
        end

        def receive_command(sock)
          req = Oj.load(sock.recv(100000), :symbol_keys => true)
          handler = Handler.new(req)
          sock.send(handler.respond, 0)
        rescue Oj::ParseError => e
          sock.send(bad_request(handler), 0)
          log_error(e)
        rescue NoMethodError => e
          sock.send(bad_request(handler), 0)
          log_error(e)
        rescue ArgumentError => e
          sock.send(bad_request(handler), 0)
          log_error(e)
        rescue => e
          sock.send(e.inspect, 0)
          log_error(e)
        end

        private

        def bad_request(handler)
          <<-OUT
The request was not formatted properly.
We suggest using Emque::Consuming::Transmitter to send a requests.",
-------
#{handler.help rescue "Help broken"}
          OUT
        end

        def log_error(e)
          logger.error(e.inspect)
          e.backtrace.each do |bt|
            logger.error(bt)
          end
        end

        class Handler
          include Emque::Consuming::Helpers

          COMMANDS = [:configuration, :errors, :restart, :status, :stop]

          def initialize(args:, command:)
            self.args = args
            self.command = command.to_sym
          end

          def help
            <<-OUT
#{app_name} Help

# Information

configuration                 # current configuration of the service
help                          # this menu
status                        # current status of the service

# Control

errors clear                  # reset the error count to 0
errors down                   # decrease the acceptable error threshold by 1
errors expire_after <seconds> # changes the expiration time for future errors
errors up                     # increase the acceptable error threshold by 1
restart                       # restart all workers
stop                          # turn the service off
-------
            OUT
          end

          def respond
            if valid_request?
              method(command).call(*args)
            else
              help
            end
          end

          private

          attr_accessor :args, :command

          def app_name
            config.app_name.capitalize
          end

          def configuration
            <<-OUT
#{app_name} Config
-------
#{config.to_hsh.map { |label, value|
  "#{label}: #{value.inspect}"
}.join("\n")}
-------
            OUT
          end

          def errors(*args)
            runner.control.errors(*args) == true ? status : help
          end

          def restart
            runner.restart_service
            "The service was successfully restarted"
          end

          def status
            data = runner.status.to_hsh
            <<-OUT
#{app_name} Status
-------
errors:
#{data[:errors].map { |attr, val|
  "  #{attr}: #{val}"
}.join("\n")}
workers:
#{data[:workers].map { |topic, settings|
  "  #{topic}: #{settings[:count]}"
}.join("\n")}
-------
            OUT
          end

          def stop
            runner.stop
          end

          def valid_request?
            COMMANDS.include?(command)
          end
        end
      end
    end
  end
end
