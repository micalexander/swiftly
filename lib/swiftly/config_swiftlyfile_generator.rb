require "thor/group"

module Swiftly
  class ConfigSwiftlyfileGenerator < Thor::Group

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
          'swiftlyfile.erb'
        ),
        File.join(
          settings[:sites_path],
          'Swiftlyfile',
        )
      )
    end
  end
end