require "inflecto"

module Emque
  module Consuming
    class AdapterConfigurationError < StandardError; end

    module Adapters; end

    class Adapter
      extend Forwardable

      attr_reader :name, :options

      def_delegators :namespace, :default_options, :manager

      def initialize(name, opts = {})
        self.name = name
        fetch_and_load
        self.options = default_options.merge(opts)
      end

      private

      attr_writer :name, :options
      attr_accessor :namespace

      def fetch_and_load
        klass = Inflecto.camelize(name.to_s)

        unless Emque::Consuming::Adapters.const_defined?(klass)
          require "emque/consuming/adapters/#{name}"
        end

        self.namespace = Inflecto.constantize(
          "Emque::Consuming::Adapters::#{klass}"
        )

        namespace.load
      rescue LoadError
        raise AdapterConfigurationError, "Unable to load requested adapter"
      rescue NameError => e
        $stdout.puts e.inspect
        raise AdapterConfigurationError, "Unknown consuming adapter"
      end
    end
  end
end
