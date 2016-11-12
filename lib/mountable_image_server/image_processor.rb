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

      parameters[:fit] ||= 'clip'

      operations_queue = [
        resize_operations,
        crop_operations,
        quality_operations,
      ].reduce([], :+)

      Tempfile.create(['processed-image', path.extname]) do |file|
        command = convert(path, to: file.path) do
          operations_queue.each do |operation|
            set *operation
          end
        end

        command.run

        yield(Pathname(file.path))
      end
    end

    private
    attr_reader :parameters, :path

    def resize_operations
      return [] unless (parameters[:fit] == 'clip') && (parameters[:h] || parameters[:w])

      [
        [:resize, "#{parameters[:w]}x#{parameters[:h]}>"]
      ]
    end

    def crop_operations
      return [] unless parameters[:fit] == 'crop' && parameters[:h] && parameters[:w]

      [
        [:resize, "#{parameters[:w]}x#{parameters[:h]}^"],
        [:gravity, 'center'],
        [:extent, "#{parameters[:w]}x#{parameters[:h]}"]
      ]
    end

    def quality_operations
      return [] unless parameters[:q]

      [
        [:quality, parameters[:q]]
      ]
    end
  end
end
