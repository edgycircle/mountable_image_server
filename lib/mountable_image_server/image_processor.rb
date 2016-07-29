require 'tempfile'
require 'pathname'
require 'skeptick'

module MountableImageServer
  class ImageProcessor
    include Skeptick

    def initialize(path, parameters)
      @parameters = parameters
      @path = path
    end

    def run(&block)
      yield(Pathname(path)) and return unless parameters[:h] || parameters[:w] || parameters[:q]

      Tempfile.create(['processed-image', path.extname]) do |file|
        command = convert(path, to: file.path) do
          set :resize, "#{parameters[:w]}x#{parameters[:h]}>" if parameters[:h] || parameters[:w]
          set :quality, parameters[:q] if parameters[:q]
        end

        command.run

        yield(Pathname(file.path))
      end
    end

    private
    attr_reader :parameters, :path
  end
end
