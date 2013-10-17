require 'Thor'
require 'obi/Version'
require 'obi/Menu'
require 'obi/Project'

module Obi
	class Controller < Thor
		include Thor::Actions
		include Obi::Version

		# Handles the creation of the .obiconfig file
		desc "config", "Maintain configuration variables"
		def config
			if (!File.exist?( CONFIG_FILE_LOCATION ))
				File.open( CONFIG_FILE_LOCATION, 'w') do |file|
					file.puts VERSION
				end
			else
				menu = Obi::Menu.new
				menu.launch_menu!
			end
		end

		desc "generate", "Generate projects by passing a project name"

		method_option :empty, :aliases => "-e", :type => :boolean
		method_option :git, :aliases => "-g", :type => :boolean
		method_option :wordpress, :aliases => "-w", :type => :boolean

		def generate(project_name)
			project = Obi::Project.new(project_name)
			case options.keys[0]
			 when "wordpress"
				project.wordpress
			 when "empty"
				project.empty
			 end
		end

	end
end
