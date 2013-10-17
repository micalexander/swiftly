require 'Thor'
require 'yaml'

module Obi
	class Configuration < Thor

		include Thor::Actions

		@config_settings = YAML.load_file(CONFIG_FILE_LOCATION) unless defined? @config_settings

		# *** tell Thor to not to run as task (no description necessary) by wrapping methods in a no_tasks do block ***

		# get config settings from config file
		no_tasks do
			def self.settings
				@config_settings
			end
		end

		# set config settings from config file
		no_tasks do
			def self.settings=(settings)
				@config_settings = YAML.load_file(settings)
				return @config_settings
			end
		end

		# update config variable values
		no_tasks do
			def update_config_setting(setting_variable, setting_value=nil)
				File.open(CONFIG_FILE_LOCATION, 'r+') do |file|
					file.each_line do |line|
						if line =~ /#{setting_variable}/
							if line =~ /(local_settings|staging_settings|production_settings)/
								setting = server_toggle(line.scan(/[^:]*$/)[0].strip)
								setting_value = setting
							end
							gsub_file CONFIG_FILE_LOCATION, /#{Regexp.escape(line)}/ do |match|
							   "#{setting_variable}: #{setting_value}\n"
							end
						end
					end
				end
			end
		end

		# toggle server settings
		no_tasks do
			def server_toggle(setting)
				possible_settings = ['enabled', 'wp-enabled', 'disabled']

				if possible_settings.include?(setting)
					case setting
					when 'enabled'
						return 'wp-enabled'
					when 'wp-enabled'
						return 'disabled'
					else
						return 'enabled'
					end
				end
			end
		end
	end
end
