require "swiftly/version"
require "thor/group"

module Swiftly
  class ConfigGlobalGenerator < Thor::Group

    include Thor::Actions

    argument :sites_path

    desc "Handles the creation of the config file."

    def self.source_root
      File.dirname(__FILE__)
    end

    def create

      @version = VERSION

      template(
        File.join(
          'templates',
          'config_global.erb'
        ),
        File.join(
          Dir.home,
          ".#{APP_NAME}"
        ),
        :verbose => false
      )

    end
  end
end