module Obi
	class MySQL

		def initialize
			@config_settings = Obi::Configuration.settings
		end

		def mysql_credentials(server)
			@server = server
			@server_setting = @config_settings["#{@server}_settings"]
			case @server_setting
			when "enabled"
				# load the obiconfig file server settings
				server_credentials  =  {
										host: "#{@config_settings["#{@server}_host"]}",
										user: "#{@config_settings["#{@server}_user"]}",
										pass: "#{@config_settings["#{@server}_password"]}",
										name: "#{@project_name}_#{@server}_wp",
										status: "\033[32menabled\033[0m"
										}
				return server_credentials
			when "wp-enabled"
				# load the wp-config file server settings
				server_credentials = Hash.new
				index_map = {
							'DB_HOST' => :host,
							'DB_USER' => :user,
							'DB_PASSWORD' => :pass,
							'DB_NAME' => :name,
							'WP_SITEURL' => :site
							}
				case @server
				when "production"
					file =	File.read( File.join( Obi::Project.project_path,
							"wp-config.php"))[/\}\s*else\s*{(\s*\/[\s|\S]*?|\s*)define\(\s*'DB_NAME[\s|\S]*?}/]
				else
					file =	File.read( File.join( Obi::Project.project_path,
							"wp-config.php"))[/\(\s*WP_ENV\s*==\s*'\s*#{@server}\s*'\s*\).*{[\s|\S]*?}/]
				end
				file.each_line do |line|
					key = line[/('|")([^('|")]*)('|").*('|")([^('|")]*)('|")/,2]
					value = line[/('|")([^('|")]*)('|").*('|")([^('|")]*)('|")/,5]
					server_credentials[index_map[key]] = value
				end
				# puts server_credentials



			else
				# do not allow
			end

		end

		def mysqldump

		end

	end
end