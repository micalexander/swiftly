module Obi
	class Environment

		def initialize

			@config_settings = Obi::Configuration.settings
		end

		def environment_settings(project_name, environment)

			@environment         = environment
			@project_name        = project_name
			@environment_setting = @config_settings["#{@environment}_settings"]

			case @environment_setting

			when "enabled"

				# load the obiconfig file environment settings for enabled environments
				environment_settings  = {
					host:        "#{@config_settings["#{@environment}_host"]}",
					user:        "#{@config_settings["#{@environment}_user"]}",
					pass:        "#{@config_settings["#{@environment}_password"]}",
					environment: "#{@environment}",
					status:      "\033[32menabled\033[0m"
				}

				return environment_settings

			when "wp-enabled"

				# load the wp-config file environment settings for wp-enabled environments
				file = File.read( File.join( Obi::Project.new(@project_name).project_path,
						"wp-config.php"))[/\$#{@environment}\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

				wp_config = JSON.parse(file)

				environment_settings  = {
					name:        "#{wp_config['name']}",
					host:        "#{wp_config['host']}",
					user:        "#{wp_config['user']}",
					pass:        "#{wp_config['pass']}",
					site:        "#{wp_config['site']}",
					environment: "#{@environment}",
					status:      "\033[32mwp-enabled\033[0m"
				}

				return environment_settings
			end
		end
	end
end