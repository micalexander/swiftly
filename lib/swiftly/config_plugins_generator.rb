require "thor/group"

module Swiftly
  class ConfigPluginsGenerator < Thor::Group

    include Thor::Actions

    desc "Handles the creation of the _plugins file."

    def self.source_root
      File.dirname(__FILE__)
    end

    def create

      settings = Swiftly::Config.load :global

      template(
        File.join(
          "templates",
          "config_plugins.erb"
        ),
        File.join(
          settings[:sites_path],
          'config',
          'plugins',
          '_plugins.yml'
        )
      )

    end
  end
end