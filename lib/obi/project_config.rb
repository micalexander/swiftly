require "thor/group"

module Obi
	class ProjectConfig < Thor::Group

		include Thor::Actions

		desc "Handles the creation of the config file."

		def self.source_root
			File.dirname(__FILE__)
		end

		def create(project_path)
			template "templates/project_config.erb", "#{project_path}/.obi/config"
		end
	end
end