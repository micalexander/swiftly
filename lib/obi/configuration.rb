require 'obi/global_config_generator'
require 'obi/version'
require 'yaml'
require 'obi/obi_module'

module Obi
	class Configuration

		include Version
		include FindAndReplace

		# get config file
		def self.global_file
			@@global_config
		end

		# get config settings from config file
		def self.settings
			self.check
			@@config_settings = YAML.load_file(@@global_config) unless defined? @@config_settings
			@@config_settings
		end

		# set config settings from config file
		def self.settings=(settings)
			@@config_settings = YAML.load_file(settings)
			return @@config_settings
		end

		# check to see if global config file has been created
		def self.check
			unless File.exist?(File.absolute_path(".obiconfig"))
				self.create
			end
			@@global_config = File.absolute_path(".obiconfig") unless defined? @@global_config
		end

		# create config file
		def self.create
			GlobalConfigGenerator.new.create
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
			# possible_settings = ['enabled', 'wp-enabled', 'disabled']
			# if possible_settings.include?(setting)
				case setting
				when 'enabled'
					return 'wp-enabled'
				when 'wp-enabled'
					return 'disabled'
				else
					return 'enabled'
				end
			# end
		end
	end
end
