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
    # `fm`     - Format of image, use 'jpg', 'png', 'gif', 'webp'
    VALID_PARAMETERS = [:fit, :w, :h, :q, :darken, :fm, :lossless]

    PARAMETER_VALUE_PATTERNS = {
      fit: /^(clip|crop)$/,
      h: /^\d+$/,
      w: /^\d+$/,
      q: /^([0-9]|[1-9][0-9]|100)$/,
      darken: /^([0-9]|[1-9][0-9]|100)$/,
      fm: /^(jpg|png|gif|webp)$/,
      lossless: /^(0|1|true|false)$/,
    }

    BOOLEAN_MAP = {
      '0' => 'false',
      '1' => 'true',
      'false' => 'false',
      'true' => 'true',
    }

    def initialize(path, parameters)
      @path = path
      @file_format = path.extname.downcase.scan(/[^\.]+/).last
      @parameters = sanitize_parameters(parameters)
    end

    def run(&block)
      yield(Pathname(path)) and return unless parameters.any?

      parameters[:fit] ||= 'clip'
      parameters[:lossless] = BOOLEAN_MAP.fetch(parameters[:lossless], 'false')

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
        lossless_operations,
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

    def sanitize_parameters(raw_parameters)
      raw_parameters.select do |key, value|
        VALID_PARAMETERS.include?(key.to_sym) && value =~ PARAMETER_VALUE_PATTERNS.fetch(key.to_sym)
      end.map do |key, value|
        [key.to_sym, value.strip.downcase]
      end.to_h
    end

    def targets_format?(format)
      if parameters[:fm]
        parameters[:fm] == format
      else
        file_format == format
      end
    end

    def darken_operations
      return [] unless parameters[:darken]

      [
        [:fill, 'black'],
        [:colorize, parameters[:darken]],
      ]
    end

    def resize_operations
      return [] unless (parameters[:fit] == 'clip') && (parameters[:h] || parameters[:w])

      [
        [:resize, "#{parameters[:w]}x#{parameters[:h]}>"],
      ]
    end

    def crop_operations
      return [] unless parameters[:fit] == 'crop' && parameters[:h] && parameters[:w]

      [
        [:resize, "#{parameters[:w]}x#{parameters[:h]}^"],
        [:gravity, 'center'],
        [:extent, "#{parameters[:w]}x#{parameters[:h]}"],
      ]
    end

    def quality_operations
      return [] unless parameters[:q] && (targets_format?('jpg') || targets_format?('webp'))

      [
        [:quality, parameters[:q]],
      ]
    end

    def format_operations
      return [] unless parameters[:fm]

      [
        [:format, parameters[:fm]],
      ]
    end

    def lossless_operations
      return [] unless parameters[:lossless] && targets_format?('webp')

      [
        [:define, 'webp:lossless=' + parameters[:lossless]],
      ]
    end
  end
end
