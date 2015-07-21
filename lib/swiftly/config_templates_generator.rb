require "thor/group"

module Swiftly
  class ConfigTemplateGenerator < Thor::Group

    include Thor::Actions

    desc "Handles the creation of the _templates file."

    def self.source_root
      File.dirname(__FILE__)
    end

    def create

      settings = Swiftly::Config.load( :global )

      template(
        File.join(
          'templates',
          'config_templates.erb'
        ),
        File.join(
          settings[:sites_path],
          'config',
          'templates',
          '_templates.yml'
        )
      )

    end
  end
end