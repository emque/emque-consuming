require "sinatra"
require "rack/router"
require "oj"

module Emque
  module Consuming
    module Http
      class Router < ::Rack::Router
        include Rack::Utils

        def map(&block)
          self.instance_eval(&block)
        end

        def route(method, route_spec)
          path, app_class = route_spec.first
          route_spec[path] = app_class
          route = Rack::Route.new(
            method,
            route_spec.first.first,
            route_spec.first.last,
            route_spec.reject{ |k, _| k == route_spec.first.first }
          )
          @routes ||= []
          @routes << route
          if route_spec && route_spec[:as]
            @named_routes[route_spec[:as].to_sym] ||= route_spec.first.first
          end
          route
        end

        def topic(mapping, &block)
          Mapping.new(self, mapping, &block)
        end

        private

        class Mapping
          attr_reader :consumer, :topic

          def initialize(router, mapping, &block)
            self.router = router
            self.topic = mapping.keys.first
            self.consumer = mapping.values.first
            self.mapping = {}

            self.instance_eval(&block)

            generate_routes
          end

          def map(map)
            mapping.merge!(map.symbolize_keys)
          end

          private

          attr_accessor :mapping, :router
          attr_writer :consumer, :topic

          def generate_routes
            mapping.each do |path, method|
              as = "#{path.to_s.gsub(".","_")}"
              uri = "/#{path.to_s.gsub(".","/")}"

              MappingApp.generate_post(
                :consumer => consumer,
                :method => method,
                :topic => topic,
                :uri => uri
              )

              action = Action.new(
                :as => as,
                :context => MappingApp,
                :uri => uri
              )

              action.via.each do |verb|
                router.route(verb, action.spec)
              end
            end

          end
        end

        class MappingApp < ::Sinatra::Base
          class << self
            def generate_post(consumer:, method:, topic:, uri:)
              post uri do
                request.body.rewind
                json = request.body.read

                message = Emque::Consuming::Message.new(
                  :original => json,
                  :topic => topic,
                  :values => Oj.load(json, :symbol_keys => true)
                )

                consumer.new.consume(method, message)
                [200, {}, ["Success"]]
              end
            end
          end
        end

        class Action
          VERBS = ["DELETE", "GET", "PATCH", "POST", "PUT"].freeze

          attr_reader :as, :context, :uri, :via

          def initialize(
            as:,
            context:,
            uri:,
            via: ["POST"]
          )
            [:context, :uri, :as, :via].each do |attr|
              self.send("#{attr}=", eval(attr.to_s))
            end
          end

          def spec
            {}.tap do |spec|
              spec[uri] = context.new
              spec[:as] = as
            end
          end

          private

          attr_writer :context, :uri

          def as=(value)
            @as = value.to_s.clone
            @as.freeze
          end

          def via=(value)
            @via = value
            @via = [via] unless via.is_a?(Array)
            @via.map(&:to_s).select!{ |verb| VERBS.include?(verb) }
            @via.uniq!
            @via.freeze
          end
        end
      end
    end
  end
end
