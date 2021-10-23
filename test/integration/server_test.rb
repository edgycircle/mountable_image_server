require 'integration_helper'

class ServerTest < IntegrationTestCase
  def setup
    MountableImageServer.configure do |config|
      config.sources << fixture_path('')
    end
  end

  def test_original_image_png
    get 'image.png'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.png'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image.png')).read, Pathname(File.join(dir, 'test.png')).read
    end
  end

  def test_original_image_jpg
    get 'image.jpg'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.jpg'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image.jpg')).read, Pathname(File.join(dir, 'test.jpg')).read
    end
  end

  def test_original_image_webp
    get 'image.webp'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.webp'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image.webp')).read, Pathname(File.join(dir, 'test.webp')).read
    end
  end

  def test_original_image_webp_alpha
    get 'image-alpha.webp'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.webp'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image-alpha.webp')).read, Pathname(File.join(dir, 'test.webp')).read
    end
  end

  def test_original_image_gif
    get 'image.gif'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.gif'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image.gif')).read, Pathname(File.join(dir, 'test.gif')).read
    end
  end

  def test_unknown_image
    get 'missing.png'

    assert_equal 404, last_response.status
  end
end
