module Emque
  module Consuming
    module Actor
      module ClassMethods
        def trap_exit(*args)
        end

        def new_link(*args)
          new(*args)
        end
      end

      module TestInstanceMethods
        def current_actor
          self
        end

        def async
          self
        end

        def after(interval)
          @test_actor_loop_count ||= 0

          if @test_actor_loop_count < 6
            @test_actor_loop_count += 1
            yield
          end
        end

        def alive?
          !@dead
        end

        def terminate
          @dead = true
        end

        def defer
          yield
        end
      end

      module InstanceMethods
      end

      def self.included(klass)
        if $TESTING
          klass.send(:include, TestInstanceMethods)
          klass.send(:include, InstanceMethods)
          klass.send(:extend, ClassMethods)
        else
          klass.send(:include, InstanceMethods)
          klass.send(:include, Celluloid)
        end
      end
    end
  end
end
