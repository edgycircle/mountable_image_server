require 'tempfile'
require 'pathname'
require 'skeptick'

module MountableImageServer
  class ImageProcessor
    include Skeptick

    # Accepted parameters and values:
    # `fit`    - Approach how to interpret width and height, use 'crop' (cropping) or 'clip' (resizing)
    # `w`      - Width of image in pixels
    # `h`      - Height of image in pixels
    # `q`      - Quality of image, use value between 0 (worst) and 100 (best)
    # `darken` - Blends image with black color, use value between 0 (no black) and 100 (completely black)
    # `fm`     - Format of image, use 'jpg', 'png', 'gif', ...
    VALID_PARAMETERS = [:fit, :w, :h, :q, :darken, :fm]

    def initialize(path, parameters)
      @path = path
      @file_format = path.extname.downcase.scan(/[^\.]+/).last
      @parameters = parameters.select do |key, value|
        VALID_PARAMETERS.include?(key.to_sym) && value =~ /\S+/
      end.map do |key, value|
        [key.to_sym, value.strip.downcase]
      end.to_h
    end

    def run(&block)
      yield(Pathname(path)) and return unless parameters.any?

      parameters[:fit] ||= 'clip'

      if parameters[:fm] && parameters[:fm] == file_format
        parameters.delete(:fm)
      end

      if parameters[:fm]
        extension = ".#{parameters[:fm]}"
      else
        extension = ".#{file_format}"
      end

      if parameters[:fm] && parameters[:fm] != file_format && file_format == 'gif'
        input_path = "#{path}[0]"
      else
        input_path = path
      end

      operations_queue = [
        format_operations,
        resize_operations,
        crop_operations,
        quality_operations,
        darken_operations,
      ].reduce([], :+)

      Tempfile.create(['processed-image', extension]) do |file|
        command = convert(input_path, to: file.path) do
          operations_queue.each do |operation|
            set *operation
          end
        end

        command.run

        yield(Pathname(file.path))
      end
    end

    private
    attr_reader :parameters, :path, :file_format

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

    def format_operations
      return [] unless parameters[:fm]

      [
        [:format, parameters[:fm]]
      ]
    end
  end
end
