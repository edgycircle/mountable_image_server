require 'unit_helper'
require 'pathname'
require 'mountable_image_server/image_locator'

class TestImageLocator < UnitTestCase
  ImageLocator = MountableImageServer::ImageLocator

  def test_locate_image_in_primary_source
    subject = ImageLocator.new([
      fixture_path('')
    ])

    result = subject.path_for('image.png')

    assert_equal Pathname(fixture_path('image.png')), result
  end

  def test_locate_image_in_alternate_source
    subject = ImageLocator.new([
      '/',
      fixture_path('')
    ])

    result = subject.path_for('image.png')

    assert_equal Pathname(fixture_path('image.png')), result
  end

  def test_handle_unknown_image
    subject = ImageLocator.new([
      fixture_path('')
    ])

    result = subject.path_for('missing.png')

    assert_nil result
  end
end
