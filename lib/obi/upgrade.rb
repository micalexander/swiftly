require "obi/Configuration"
require "obi/Obi_module"

module Obi
	class Upgrade

		include ProjectExist
		extend ProjectExist

		@@settings = Configuration.settings 'upgrade'

		def self.check

			if @@settings =~ /version='2.0'/
				puts
				puts "obi: I'm sorry, I'm out of date. To upgrade, please run [ obi upgrade ]. All settings will be preserved"
				puts
				exit
			end

		end

		def self.global_config

			global_config = Configuration.global_file

			if File.exists? global_config

				if @@settings['version'] != 'version'
					puts
					puts "obi: You already have the latest version"
					puts
				else
					pattern = /(^(version|local|staging|production)([a-z]*?))(=')(.*?)'\n/

					string = File.read global_config

					file = string.gsub( pattern ) do |match|
						head = $2
						body = $3
						tail = $5

						if head =~ /version/
							"#{head}#{body}: #{VERSION}\n\n"
						elsif body =~ /project/
							"#{head}_project_directory: #{tail}\n"
						else
							"#{head}_#{body}: #{tail}\n"
						end
					end

					open global_config, 'w' do |io|
						io.write file
					end
					puts
					puts "obi: obi has been successfully updated."
					puts
				end
			else
				puts
				puts "obi: Couldn't find a global config file, run [ obi config ] to get started"
				puts
				exit
			end
		end

		def self.project_config project_name

			if project_name

				project_config = File.join( @@settings['local_project_directory'], project_name, '.obi', 'config' )
				if YAML.load_file( project_config )['enable_production_ssh'] != 'enable_production_ssh'
					puts
					puts  "obi: #{project_name} is already \033[32mup to date\033[0m."
					puts
				else
					project? File.join( @@settings['local_project_directory'], project_name )

					pattern = /((^[a-zA-Z\d_]*?)(='|=\()(('.*?|.*?)('\n|'\))))|((\#(\s|\S)(.*?)\n\#))/

					string = File.read project_config

					file = string.gsub( pattern ) do |match|
						head = $2
						body = $4
						tail = $5
						foot = $7

						direc = ""
						if head =~ /rsync_dirs/
							body.split(' ').each do |b|
								direc << "\n- #{b[/'(.*?)'/,1]}"
							end
							"#{head}: #{direc}"
						elsif head =~ /sshmysql/
							new_head = head.gsub(/sshmysql/, 'ssh_sql')
							"#{new_head}: #{tail}\n"
						elsif foot =~ /#/
							"#{foot}\n"
						else
							"#{head}: #{tail}\n"
						end
					end

					open project_config, 'w' do |io|
						io.write file
					end
					puts
					puts  "obi: #{project_name} has been successfully updated."
					puts
				end
			else
				puts
				puts "obi: Please provide a project name to upgrade"
				puts
				exit
			end

		end

		def self.all
			global_config

			projects = Dir.glob(File.join( @@settings['local_project_directory'],'*' )).select {|f| File.directory? f}
			projects.each do |project|
				if File.exists? File.join( project, '.obi', 'config' )
					project_config File.basename project
				else
					puts
					puts  "obi: #{File.basename project} does not contain an \033[33m.obi/config file.\033[0m"
					puts
				end

			end
		end
	end
end
