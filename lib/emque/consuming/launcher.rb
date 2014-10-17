require 'fileutils'

module Emque
  module Consuming
    class Launcher
      def initialize(options)
        self.options = options
      end

      def start
        daemonize! if daemonize?
        pidfile = write_pid

        read_pipe, write_pipe = IO.pipe

        ["USR1", "INT", "TERM"].each do |signal|
          trap(signal) do
            write_pipe.puts(signal)
          end
        end

        begin
          self.application =
            Emque::Consuming.application.instance =
            Emque::Consuming.application.new

          application.pidfile = pidfile

          application.start

          unless $TESTING
            while rx_array = IO.select([read_pipe])
              rx_array.first.each do |rx|
                signal = rx.gets.chomp
                handle_signal(signal)
              end
            end
          end
        rescue Interrupt
          # unclean shutdown, currently attempts "clean" shutdown
          application.shutdown

          exit(0)
        end
      end

      def stop
        pidfile = options[:pidfile]
        timeout = options[:timeout]

        done("No pidfile given") unless pidfile
        done("Pidfile #{pidfile} does not exist") unless File.exist?(pidfile)

        pid = File.read(pidfile).to_i
        done("Invalid pidfile content") if pid == 0

        begin
          Process.getpgid(pid)
        rescue Errno::ESRCH
          done "Process doesn't exist"
        end

        `kill -TERM #{pid}`
        timeout.times do
          begin
            Process.getpgid(pid)
          rescue Errno::ESRCH
            FileUtils.rm_f pidfile
            done "Emque shut down gracefully."
          end
          sleep 1
        end
        `kill -9 #{pid}`
        FileUtils.rm_f pidfile
        done "Emque shut down forcefully."
      end

      private

      attr_accessor :options, :application

      def handle_signal(signal)
        case signal
        when "USR1"
          # clean shut down
          application.shutdown
          exit(0)
        when "INT"
          raise Interrupt
        when "TERM"
          raise Interrupt
        end
      end

      def daemonize?
        options[:d]
      end

      def daemonize!
        Process.daemon(true, true)

        [$stdout, $stderr].each do |io|
          File.open(Emque::Consuming::Application.application.logfile, 'ab') do |f|
            io.reopen(f)
          end
          io.sync = true
        end
        $stdin.reopen('/dev/null')
      end

      def write_pid
        pid_file = options[:pidfile] || File.join(Emque::Consuming::Application.application.root, "tmp/pids")

        Dir.mkdir(File.dirname(pid_file)) unless File.exist?(File.dirname(pid_file))

        File.open(pid_file, 'w') do |f|
          f.puts Process.pid
        end

        at_exit do
          FileUtils.rm_f pid_file
        end

        pid_file
      end

      def done(msg)
        puts msg
        exit(0)
      end
    end
  end
end
