require 'Thor'
require 'obi/Version'
require 'obi/Menu'

module Obi
	class Controller < Thor
		include Thor::Actions
		include Obi::Version

		# Handles the creation of the .obiconfig file
		desc "config", "Maintain configuration variables"
		def config
			config_file = '../../.obiconfig'
			if (!File.exist?( config_file ))
				File.open( config_file, 'w') do |file|
					file.puts VERSION
				end
			else
				menu = Obi::Menu.new
				menu.launch_menu!
			end
		end


	end
end
