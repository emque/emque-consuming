require "active_support/core_ext"

module Emque
  module Consuming
    module Consumer
      module ClassMethods
        def inherited(klass)
          klass.send(:before_filters=, (before_filters || []).dup)
          klass.send(:after_filters=, (after_filters || []).dup)
        end

        def each_before_filter(action, &block)
          self.before_filters = [] if !before_filters
          each_filter(before_filters, action, &block)
        end

        def each_after_filter(action, &block)
          self.after_filters = [] if !after_filters
          each_filter(after_filters, action, &block)
        end

        private

        attr_accessor :before_filters, :after_filters

        def each_filter(filters, action)
          filters.each do |filter|
            if filter[:actions].include?(action.to_sym) || filter[:all]
              yield(filter[:filter])
            end
          end
        end

        def before_all(name: nil, &filter)
          before(:all => true, :name => name, &filter)
        end

        def before(*actions, all: false, name: nil, &filter)
          self.before_filters = [] if !before_filters
          add_filter(before_filters, actions, all, name, filter)
        end

        def after_all(name: nil, &filter)
          after(:all => true, :name => name, &filter)
        end

        def after(*actions, all: false, name: nil, &filter)
          self.after_filters = [] if !after_filters
          add_filter(after_filters, actions, all, name, filter)
        end

        def add_filter(filters, actions, all, name, filter)
          actions = actions.map(&:to_sym)

          filters.push(
            :actions => actions,
            :name => name,
            :filter => filter,
            :all => all
          )
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
        base.send(:attr_reader, :message)
      end

      def consume(handler_method, message)
        @message = message

        self.class.each_before_filter(handler_method) do |filter|
          instance_exec(&filter)
        end

        value = send(handler_method)

        self.class.each_after_filter(handler_method) do |filter|
          instance_exec(&filter)
        end

        value
      end
    end
  end
end
