require "thor/group"

module Obi
	class TemplatesConfig < Thor::Group

		include Thor::Actions

		desc "Handles the creation of the _templates file."

		def self.source_root
			File.dirname(__FILE__)
		end

		def create
			template "templates/templates_config.erb", File.join( Configuration.settings['local_project_directory'], '.obi', 'templates', '_templates.yml')
		end
	end
end