require "dry-configurable"

require "mountable_image_server/version"

module MountableImageServer
  extend Dry::Configurable

  setting :sources, []
end
