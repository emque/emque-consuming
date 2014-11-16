require "fileutils"

module Emque
  module Consuming
    class Pidfile
      extend Forwardable

      attr_reader :path

      def_delegators :pid, :to_i, :to_s

      def initialize(path)
        self.path = path
        ensure_dir_exists
        self.pid = File.read(path).to_i if File.exists?(path)
      end

      def running?
        if pid
          if pid == 0
            rm_file
          else
            begin
              Process.getpgid(pid)
              return true
            rescue Errno::ESRCH
              rm_file
            end
          end
        end
        false
      end

      def write
        File.open(path, "w") do |f|
          f.puts Process.pid
        end
      end

      private

      attr_writer :path
      attr_accessor :pid

      def ensure_dir_exists
        FileUtils.mkdir_p(File.dirname(path))
      end

      def rm_file
        FileUtils.rm_f(path) if File.exists?(path)
      end
    end
  end
end
