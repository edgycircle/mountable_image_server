require 'sinatra/base'
require 'pathname'

module MountableImageServer
  class Server < Sinatra::Base
    get '/:fid' do |fid|
      path = Pathname(MountableImageServer.config.source) + fid

      send_file path
    end
  end
end
