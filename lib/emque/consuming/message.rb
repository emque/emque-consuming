require "virtus"

module Emque
  module Consuming
    class Message
      include Virtus.value_object

      values do
        attribute :offset, Integer
        attribute :original, Object
        attribute :partition, Integer
        attribute :status, Symbol, :default => :processing
        attribute :topic, Symbol, :default => :unknown
        attribute :values, Hash, :default => {}
      end

      def continue?
        status == :processing
      end
    end
  end
end
