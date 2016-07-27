require 'sinatra/base'
require 'mountable_image_server/image_locator'

module MountableImageServer
  class Server < Sinatra::Base
    get '/:fid' do |fid|
      locator = ImageLocator.new(MountableImageServer.config.sources)

      if path = locator.path_for(fid)
        send_file(path)
      else
        halt(404)
      end
    end
  end
end
