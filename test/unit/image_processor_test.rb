require 'unit_helper'
require 'pathname'
require 'mountable_image_server/image_processor'
require 'skeptick'

class TestImageProcessor < UnitTestCase
  ImageProcessor = MountableImageServer::ImageProcessor

  def test_run_processor_without_parameters
    path = Pathname(fixture_path('image.png'))
    parameters = {}
    subject = ImageProcessor.new(path, parameters)

    subject.run do |processed_path|
      assert_equal path, processed_path
    end
  end

  def test_run_processor_with_quality_parameter
    # There is no quality for PNG like there is for JPEG
    # therefore we can not check the result properly
    [
      ['unsplash-pcvpM9Ec5LY-h640.jpg', { q: '50' }],
    ].each do |(file_name, parameters)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_quality = detect_image_information(:quality, processed_path)

        assert_equal parameters[:q], processed_quality, "Quality does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_format_parameter
    [
      ['unsplash-10Wq29jSmvM-h640.jpg', { fm: 'png' }, 'PNG'],
      ['unsplash-10Wq29jSmvM-h640.tiff', { fm: 'jpg' }, 'JPEG'],
      ['image.png', { fm: 'jpg' }, 'JPEG'],
      ['image.png', { fm: 'gif' }, 'GIF'],
      ['image.gif', { fm: 'jpg' }, 'JPEG'],
      ['image.gif', { fm: 'png' }, 'PNG'],
    ].each do |(file_name, parameters, expected_format)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_format = detect_image_information(:format, processed_path)

        assert_equal expected_format, processed_format, "Format does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_width_parameter
    [
      ['unsplash-Wv0F89mi660-w640.jpg', { w: '100' }],
      ['image.png', { w: '100' }],
    ].each do |(file_name, parameters)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_width = detect_image_information(:width, processed_path)

        assert_equal parameters[:w], processed_width, "Width does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_height_parameter
    [
      ['unsplash-pcvpM9Ec5LY-h640.jpg', { h: '100' }],
      ['image.png', { h: '100' }],
    ].each do |(file_name, parameters)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_height = detect_image_information(:height, processed_path)

        assert_equal parameters[:h], processed_height, "Height does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_combined_with_and_height_parameter
    [
      ['unsplash-pcvpM9Ec5LY-h640.jpg', { w: '100', h: '100' }, :portrait],
      ['unsplash-Wv0F89mi660-w640.jpg', { w: '100', h: '100' }, :landscape],
      ['image.png', { w: '100', h: '100' }, :square],
    ].each do |(file_name, parameters, initial_orientation)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        # The larger dimension will match exactly
        # the other dimension will be less than the passed limit
        case initial_orientation
        when :landscape
          processed_width = detect_image_information(:width, processed_path)

          assert_equal parameters[:w], processed_width, "Width does not match for image '#{file_name}' with parameters #{parameters}."
        when :portrait
          processed_height = detect_image_information(:height, processed_path)

          assert_equal parameters[:h], processed_height, "Height does not match for image '#{file_name}' with parameters #{parameters}."
        when :square
          processed_width = detect_image_information(:width, processed_path)
          processed_height = detect_image_information(:height, processed_path)

          assert_equal parameters[:w], processed_width, "Width does not match for image '#{file_name}' with parameters #{parameters}."
          assert_equal parameters[:h], processed_height, "Height does not match for image '#{file_name}' with parameters #{parameters}."
        end
      end
    end
  end

  def test_run_processor_with_combined_with_and_height_to_crop_parameter
    [
      ['unsplash-pcvpM9Ec5LY-h640.jpg', { fit: 'crop', w: '100', h: '80' }],
      ['unsplash-Wv0F89mi660-w640.jpg', { fit: 'crop', w: '100', h: '80' }],
      ['image.png', { fit: 'crop', w: '100', h: '80' }],
    ].each do |(file_name, parameters)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_width = detect_image_information(:width, processed_path)
        processed_height = detect_image_information(:height, processed_path)

        assert_equal parameters[:w], processed_width, "Width does not match for image '#{file_name}' with parameters #{parameters}."
        assert_equal parameters[:h], processed_height, "Height does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_combined_parameters_on_large_image
    [
      ['david-12.jpg', { fit: 'crop', w: '100', h: '80' }, 'JPEG'],
    ].each do |(file_name, parameters, expected_format)|
      subject = ImageProcessor.new(Pathname(fixture_path(file_name)), parameters)

      subject.run do |processed_path|
        processed_width = detect_image_information(:width, processed_path)
        processed_height = detect_image_information(:height, processed_path)
        processed_format = detect_image_information(:format, processed_path)

        assert_equal parameters[:w], processed_width, "Width does not match for image '#{file_name}' with parameters #{parameters}."
        assert_equal parameters[:h], processed_height, "Height does not match for image '#{file_name}' with parameters #{parameters}."
        assert_equal expected_format, processed_format, "Format does not match for image '#{file_name}' with parameters #{parameters}."
      end
    end
  end

  def test_run_processor_with_non_sense_parameter
    [
      ['image.jpg', { q: '' }],
      ['image.jpg', { q: 'a' }],
      ['image.jpg', { q: '101' }],
      ['image.jpg', { fit: '' }],
      ['image.jpg', { fit: '0' }],
      ['image.jpg', { fit: 'abc' }],
      ['image.jpg', { fm: '' }],
      ['image.jpg', { fm: 'foo' }],
      ['image.jpg', { w: '' }],
      ['image.jpg', { w: 'foo' }],
      ['image.jpg', { h: '' }],
      ['image.jpg', { h: 'foo' }],
      ['image.jpg', { darken: '' }],
      ['image.jpg', { darken: 'a' }],
      ['image.jpg', { darken: '101' }],
    ].each do |(file_name, parameters)|
      path = Pathname(fixture_path(file_name))
      subject = ImageProcessor.new(path, parameters)

      subject.run do |processed_path|
        # Non-sense parameters will be ignored,
        # therefore the original image will not be modified
        assert_equal path, processed_path, "Image '#{file_name}' with parameters #{parameters} has been modified although it shouldn't."
      end
    end
  end

  private
  def detect_image_information(property, path)
    # Docs about formatting information:
    # https://legacy.imagemagick.org/script/escape.php
    map = {
      quality: "-format '%Q'",
      format: "-format '%m'",
      width: "-format '%w'",
      height: "-format '%h'",
    }

    raise "Unknown property '#{property}' to get from image." unless map.has_key?(property)

    `identify #{map.fetch(property)} #{path.to_s}`
  end
end
