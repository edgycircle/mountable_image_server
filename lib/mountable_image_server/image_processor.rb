require 'tempfile'
require 'pathname'
require 'skeptick'

module MountableImageServer
  class ImageProcessor
    include Skeptick

    VALID_PARAMETERS = [:fit, :crop, :w, :h, :q, :darken]

    def initialize(path, parameters)
      @path = path
      @parameters = parameters.select do |key, value|
        VALID_PARAMETERS.include?(key.to_sym)
      end.map do |key, value|
        [key.to_sym, value]
      end.to_h
    end

    def run(&block)
      yield(Pathname(path)) and return unless parameters.any?

      parameters[:fit] ||= 'clip'

      operations_queue = [
        resize_operations,
        crop_operations,
        quality_operations,
        darken_operations
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

    def darken_operations
      return [] unless parameters[:darken]

      [
        [:fill, 'black'],
        [:colorize, parameters[:darken]]
      ]
    end

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
