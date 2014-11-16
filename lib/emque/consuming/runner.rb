require "emque/consuming/application"
require "emque/consuming/control"
require "emque/consuming/pidfile"
require "emque/consuming/status"
require "emque/consuming/command_receivers/http_server"
require "emque/consuming/command_receivers/unix_socket"
require "emque/consuming/transmitter"

module Emque
  module Consuming
    class Runner
      include Emque::Consuming::Helpers

      class << self
        attr_accessor :instance
      end

      attr_reader :control, :pidfile, :status

      def initialize(options = {})
        self.control = Emque::Consuming::Control.new
        self.options = options
        self.receivers = []
        self.status = Emque::Consuming::Status.new
        apply_options
        Emque::Consuming.application.initialize_logger
        self.class.instance = self
        self.pidfile = options.fetch(:pidfile, default_pidfile)
        self.pid = Emque::Consuming::Pidfile.new(pidfile)
      end

      def app
        super
      end

      def console
        require "pry"
        Pry.start
      end

      def http?
        config.status == :on
      end

      def phased_restart
        receivers.each { |r| r.stop && r.start }
      end

      def restart
        stop && start
      end

      def restart_service
        receivers.first.restart
      end

      def sock?
        true
      end

      def start
        exit_if_already_running!
        daemonize! if daemonize?
        write_pidfile!
        @persist = Thread.new { loop { sleep 1 } }
        set_process_title
        setup_receivers
        receivers.each(&:start)
        persist.join
      rescue Interrupt
        stop
      end

      def stop(timeout: 5)
        if persist
          Thread.new do
            sleep timeout
            logger.error("Timeout Exceeded. Forcing Shutdown.")
            persist.exit if persist.alive?
          end
          receivers.each(&:stop)
          logger.info("Graceful shutdown successful.")
          logger.info("#{config.app_name.capitalize} stopped.")
          persist.exit if persist.alive?
        else
          Emque::Consuming::Transmitter.send(
            :command => :stop,
            :socket_path => config.socket_path
          )
        end
      end

      private

      attr_accessor :options, :persist, :pid, :receivers
      attr_writer :control, :pidfile, :status

      def apply_options
        options.each do |attr, val|
          config.send("#{attr}=", val) if config.respond_to?(attr)
        end
      end

      def config
        Emque::Consuming.application.config
      end

      def daemonize?
        options[:daemon]
      end

      def daemonize!
        Process.daemon(true, true)

        [$stdout, $stderr].each do |io|
          File.open(Emque::Consuming.application.logfile, 'ab') do |f|
            io.reopen(f)
          end
          io.sync = true
        end

        $stdin.reopen('/dev/null')
      end

      def default_pidfile
        File.join(
          Emque::Consuming.application.root,
          "tmp",
          "pids",
          "#{config.app_name}.pid"
        )
      end

      def exit_if_already_running!
        if pid.running?
          [
            "Pid file exists. Process #{pid} active.",
            "Please ensure app is not running."
          ].each do |msg|
            logger.error(msg)
            $stdout.puts(msg)
          end

          exit
        end
      end

      def set_process_title
        title = "#{config.app_name} [pidfile: #{pidfile}"
        title << " | unix socket: #{config.socket_path}" if sock?
        title << " | http://#{config.status_host}:#{config.status_port}" if http?
        title << "]"
        $0 = title
      end

      def setup_receivers
        receivers << app
        receivers << Emque::Consuming::CommandReceivers::UnixSocket.new if sock?
        receivers << Emque::Consuming::CommandReceivers::HttpServer.new if http?
      end

      def write_pidfile!
        pid.write
        at_exit { FileUtils.rm_f(pidfile) }
      end
    end
  end
end
