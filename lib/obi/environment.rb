module Obi
	class Environment

		def initialize
			@config_settings = Obi::Configuration.settings
		end

		def environment_settings(project_name, environment)
			@environment = environment
			@project_name = project_name
			@environment_setting = @config_settings["#{@environment}_settings"]
			case @environment_setting
			when "enabled"
				# load the obiconfig file environment settings for enabled environments
				environment_settings  = {
										host: "#{@config_settings["#{@environment}_host"]}",
										user: "#{@config_settings["#{@environment}_user"]}",
										pass: "#{@config_settings["#{@environment}_password"]}",
										environment: "#{@environment}",
										status: "\033[32menabled\033[0m"
										}
				return environment_settings
			when "wp-enabled"
				# load the wp-config file environment settings for wp-enabled environments
				environment_settings = Hash.new
				index_map = {
							'DB_HOST' => :host,
							'DB_USER' => :user,
							'DB_PASSWORD' => :pass,
							'DB_NAME' => :name,
							'WP_SITEURL' => :site
							}
				case @environment
				when "production"
					file =	File.read( File.join( Obi::Project.new(@project_name).project_path,
							"wp-config.php"))[/\}\s*else\s*{(\s*\/[\s|\S]*?|\s*)define\(\s*'DB_NAME[\s|\S]*?}/]
				else
					file =	File.read( File.join( Obi::Project.new(@project_name).project_path,
							"wp-config.php"))[/\(\s*WP_ENV\s*==\s*'\s*#{@environment}\s*'\s*\).*{[\s|\S]*?}/]
				end
				file.each_line do |line|
					key = line[/('|")(.*?)('|")(.*?)('|")(.*?)('|")/,2]
					value = line[/('|")(.*?)('|")(.*?)('|")(.*?)('|")/,6]
					environment_settings[index_map[key]] = value
				end
				environment_settings[:environment] = "#{@environment}"
				environment_settings[:status] = "\033[32mwp-enabled\033[0m"
				return environment_settings.delete_if { |k, v| v.nil? }
			else
				# do not allow
			end
		end
	end
end