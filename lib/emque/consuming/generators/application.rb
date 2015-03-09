require "erb"
require "fileutils"
require "optparse"

module Emque
  module Consuming
    module Generators
      class Application
        IGNORE = [".", ".."]

        def initialize(options, name)
          self.name = Inflecto.underscore(name)
          self.options = options
        end

        def generate
          context = Class.new(Object) { |obj|
            def initialize(options, name)
              @name = name.camelize
              @options = options
            end

            def get_binding; binding; end
          }.new(options, name).get_binding

          @current_dir = File.realdirpath(Dir.pwd)

          recursively_copy_templates(
            File.realdirpath(
              File.join(
                File.dirname(__FILE__),
                "..",
                "..",
                "..",
                "templates"
              )
            ),
            [current_dir, name],
            context
          )
        end

        private

        attr_accessor :name, :options
        attr_reader :current_dir

        def relative_path(path)
          path.gsub(current_dir, ".")
        end

        def recursively_copy_templates(path, nesting, context)
          Dir.entries(path).each do |e|
            unless IGNORE.include?(e)
              loc = File.join(path, e)

              if Dir.exists?(loc)
                new_nest = nesting + [e]
                create_path = File.join(*new_nest)

                unless Dir.exists?(create_path)
                  FileUtils.mkdir_p(create_path)
                  puts "created directory #{relative_path(create_path)}"
                end

                recursively_copy_templates(loc, new_nest, context)
              elsif e =~ /\.tt$/
                filename = File.join(
                  FileUtils.mkdir_p(File.join(*nesting)).first,
                  e.gsub(".tt", "")
                )
                display = relative_path(filename)
                overwrite = "Y"

                if File.exists?(filename)
                  print "#{display} exists, overwrite? (yN) "
                  overwrite = $stdin.gets
                end

                if overwrite.upcase.chomp == "Y"
                  File.open(filename, "w") do |f|
                    f.write(ERB.new(File.read(loc)).result(context))
                  end
                  puts "created file #{display}"
                else
                  puts "skipping file #{display}"
                end
              end
            end
          end
        end
      end
    end
  end
end
