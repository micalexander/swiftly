require 'obi/configuration'
require 'uri'
require 'yaml'

module Obi
	class Templates

		def self.templates_file
			local_project_directory = Configuration.settings['local_project_directory']
			File.join local_project_directory, '.obi', 'templates', '_templates.yml' unless !File.exists? File.join local_project_directory, '.obi', 'templates', '_templates.yml'
		end

		def self.settings_check
			if self.templates_file
				return YAML.load_file self.templates_file
			end
		end

		def self.search_templates( template_choice = nil )

			if self.settings_check
				if self.settings_check.count > 0
					self.settings_check['templates'].each do |template|
						if template['name'] == template_choice
							return template.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
						end
					end
					return { :name=>template_choice, :remote=>false }
				else
					puts "\nobi: there are no templates listed in the _templates.yml file\n\n"
				end
				exit
			end
		end

		def self.load_template( template = '', options = {:name=> nil, :remote=>false, :enabled=>true} )

			if template.empty?
				return 'https://github.com/micalexander/mask/archive/master.zip'
			else

				searched_template = self.search_templates( template )

				# reserve arguement defaults by merging options with the given hash
				template_values = options.merge searched_template

				# check to see if the user has disabled requested template

				if template_values[:enabled] == true

					# check to see if remote is set to false for requested template
					if template_values[:remote] == false
						# set found_template to requested template if template folder can be found in template directory
						found_template = File.join Configuration.settings['local_project_directory'], '.obi', 'templates', template unless !File.exists? File.join Configuration.settings['local_project_directory'], '.obi', 'templates', template
					else
						# set found_template to remote address provided
						found_template = template_values[:remote]
					end

					# check to see if found template is set to a directory or url
					if found_template and found_template != true and File.directory? found_template or found_template =~ /^#{URI::regexp}$/
						return found_template
					else
						abort "\nobi: the template \"#{template}\" could not be found\n\n"
					end
				else
					abort "\nobi: the template \"#{template}\" is not enabled\n\n"
				end
			end

		end
	end
end