require "fileutils"
require "socket"
require "oj"

module Emque
  module Consuming
    module Transmitter
      def self.send(command:, socket_path: "tmp/emque.sock", args: [])
        if File.exists?(socket_path)
          socket = UNIXSocket.new(socket_path)
          socket.send(Oj.dump({
            :command => command,
            :args => args
          }, :mode => :compat), 0)
          response = socket.recv(10000000)
          socket.close
          response
        else
          "Socket not found at #{socket_path}"
        end
      rescue Errno::ECONNREFUSED
        FileUtils.rm_f(socket_path) if File.exists?(socket_path)
        "The UNIX Socket found at #{socket_path} was dead"
      end

      def self.method_missing(method, *args)
        send(command: method, args: args)
      end
    end
  end
end
