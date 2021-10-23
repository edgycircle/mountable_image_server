require 'sinatra/base'
require 'mountable_image_server/image_locator'
require 'mountable_image_server/image_processor'

module MountableImageServer
  class Server < Sinatra::Base
    get '/:fid' do |fid|
      locator = ImageLocator.new(MountableImageServer.config.sources)

      begin
        respond_with_image(locator, fid, params)
      rescue Skeptick::ImageMagickError => e
        if e.message.include?('convert: unable to open image')
          respond_with_image(locator, fid, params)
        else
          halt(404)
        end
      end
    end

    private
    def respond_with_image(locator, fid, params)
      if path = locator.path_for(fid)
        image_processor = ImageProcessor.new(path, params)

        image_processor.run do |processed_image_path|
          content_type(supported_mime_types_by_extname.fetch(processed_image_path.extname.downcase))
          body(processed_image_path.read)
        end
      else
        halt(404)
      end
    end

    def supported_mime_types_by_extname
      # Rack::Mime::MIME_TYPES does not support
      # `.webp` in latest released version (2.2.3 as of now)
      # https://github.com/rack/rack/blob/2.2.3/lib/rack/mime.rb
      {
        '.jpeg' => 'image/jpeg',
        '.jpg'  => 'image/jpeg',
        '.png'  => 'image/png',
        '.gif'  => 'image/gif',
        '.webp' => 'image/webp',
      }.merge(Rack::Mime::MIME_TYPES.dup)
    end
  end
end
