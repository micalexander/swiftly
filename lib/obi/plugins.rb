require 'obi/configuration'
require 'yaml'

module Obi
	class Plugins

		def self.plugin_file
			local_project_directory = Configuration.settings['local_project_directory']
			File.join local_project_directory, '.obi', 'plugins', '_plugins.yml' unless !File.exists? File.join local_project_directory, '.obi', 'plugins', '_plugins.yml'
		end

		def self.settings_check
			if self.plugin_file
				return YAML.load_file self.plugin_file
			end
		end

		def self.list_plugins
			plugins = self.settings_check
			plugins_found = ""
			plugin_not_found = ""
			if plugins
				# puts plugins
				# exit
				if ( plugins.count > 0 && plugins != nil)
					plugins['plugins'].each do |plugin|
						found_plugin = File.join Configuration.settings['local_project_directory'], '.obi', 'plugins', plugin
						plugins_found += "run_activate_plugin( '#{plugin}' );\n" unless !File.exists? found_plugin
						plugin_not_found += "\n//obi: plugin not found - " + plugin unless File.exists? found_plugin
					end
				else
					return "\n//obi: 1there were no plugins listed in the _plugin.yml file\n\n"
				end
				return plugins_found, plugin_not_found + "\n\n"
			else
				return "\n//obi: there were no plugins listed in the _plugin.yml file\n\n"
			end
		end

		def self.add_plugins_to_functions_file project_path
			found, not_found = self.list_plugins

			functions_file = File.join project_path,'wp-content', 'themes', File.basename( project_path ), 'functions.php'

			pattern = /(.)(\n*?|\n*\?>\n*)\Z/

			string = File.read functions_file

			file = string.gsub( pattern ) do |match|
				head = $1
				"#{head}\n\n#{found}#{not_found}\?\>"
			end

			open functions_file, 'w' do |io|
				io.write file
			end
		end

	end
end