require 'obi/global_config'
require 'yaml'
require 'obi/obi_module'

module Obi
	class Configuration

		include FindAndReplace

		# get config file
		def self.global_file
			@@global_config = File.absolute_path( File.join(Dir.home, ".obiconfig" ))
		end

		# get config settings from config file
		def self.settings(pass_thru = nil)
			self.check
			unless pass_thru
			    if !File.directory?(@@config_settings['local_project_directory'].to_s)
	                abort "\nobi: Please run obi config and set your project working directory and any other necessary settings.\n\n"
	            elsif @@config_settings['local_host'] == 0 or @@config_settings['local_user'] == 0 or @@config_settings['local_password'] == 0 or @@config_settings['local_settings'] == 0
	                abort "\nobi: Please run obi config and verify that all of your local environment settings are set.\n\n"
	            else
	            	@@config_settings
	            end
	        else
	        	@@config_settings
	        end
		end

		# set config settings from config file
		def self.settings=(settings)
			@@config_settings = YAML.load_file(settings)
			return @@config_settings
		end

		# check to see if global config file has been created
		def self.check

			unless File.exist? self.global_file
				self.create
			end
			@@global_config = self.global_file unless defined? @@global_config
			@@config_settings = YAML.load_file(@@global_config) unless defined? @@config_settings
		end

		# create config file
		def self.create
			GlobalConfig.new.create
		end

		# update config variable values
		def update_config_setting(setting_variable, setting_value=nil)
			global_config = Obi::Configuration.global_file
			File.open(global_config, 'r+') do |file|
				file.each_line do |line|
					if line =~ /#{setting_variable}/
						if line =~ /(local_settings|staging_settings|production_settings)/
							setting_value = server_toggle(line.scan(/[^:]*$/)[0].strip)
						end
						find_and_replace(input: global_config, pattern: /#{Regexp.escape(line)}/, output: "#{setting_variable}: #{setting_value}\n", file: true)
					end
				end
			end
		end

		# toggle server settings
		def server_toggle(setting)
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
