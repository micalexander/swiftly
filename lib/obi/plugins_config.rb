require "thor/group"

module Obi
	class PluginsConfig < Thor::Group

		include Thor::Actions

		desc "Handles the creation of the _plugins file."

		def self.source_root
			File.dirname(__FILE__)
		end

		def create
			template "templates/plugins_config.erb", File.join( Configuration.settings['local_project_directory'], '.obi', 'plugins', '_plugins.yml')
		end
	end
end