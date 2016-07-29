require 'sinatra/base'
require 'mountable_image_server/image_locator'
require 'mountable_image_server/image_processor'

module MountableImageServer
  class Server < Sinatra::Base
    get '/:fid' do |fid|
      locator = ImageLocator.new(MountableImageServer.config.sources)

      if path = locator.path_for(fid)
        image_processor = ImageProcessor.new(path, params)

        image_processor.run do |processed_image_path|
          cache_control :public, max_age: 500000
          content_type(Rack::Mime::MIME_TYPES.fetch(processed_image_path.extname.downcase))
          body(processed_image_path.read)
        end
      else
        halt(404)
      end
    end
  end
end
