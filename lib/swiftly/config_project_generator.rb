require "thor/group"

module Swiftly
	class ConfigProjectGenerator < Thor::Group

		include Thor::Actions

		desc "Handles the creation of the config file."

		def self.source_root

			File.dirname(__FILE__)

		end

		def create( project_path )

			template(
				File.join(
					'templates',
					'config_project.erb'
				),
				File.join(
					project_path,
					'config',
					'config.yml'
				)
			)

		end
	end
end