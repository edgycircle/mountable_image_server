require 'integration_helper'

class TestServer < IntegrationTestCase
  def setup
    MountableImageServer.configure do |config|
      config.sources << fixture_path('')
    end
  end

  def test_original_image
    get 'image.png'

    Dir.mktmpdir('downloads') do |dir|
      File.open(File.join(dir, 'test.png'), 'wb') { |file| file.write(last_response.body) }
      assert_equal Pathname(fixture_path('image.png')).read, Pathname(File.join(dir, 'test.png')).read
    end
  end

  def test_unknown_image
    get 'missing.png'

    assert_equal 404, last_response.status
  end
end
