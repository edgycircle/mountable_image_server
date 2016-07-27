require 'pathname'

module MountableImageServer
  class ImageLocator
    def initialize(sources)
      @sources = sources
    end

    def path_for(filename)
      possible_paths = sources.map do |source|
        Pathname(source) + filename
      end

      possible_paths.detect do |path|
        path.exist?
      end
    end

    private
    attr_reader :sources
  end
end
