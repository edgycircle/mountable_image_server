require "dry-configurable"

require "mountable_image_server/version"

module MountableImageServer
  require "mountable_image_server/server"

  extend Dry::Configurable

  setting :sources, []
end
