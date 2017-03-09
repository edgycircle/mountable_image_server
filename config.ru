$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)

require './lib/mountable_image_server'

MountableImageServer.configure do |config|
  config.sources << './test/fixtures'
end

run MountableImageServer::Server.new
