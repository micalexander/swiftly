require 'obi/obi_module'
require 'open3'

module Obi
	class Rsync
		include ProjectExist
		extend ProjectExist

		# pull content from to
		def self.sync(project_name, origin, destination)
			config_settings = Configuration.settings
			project?( File.join(config_settings['local_project_directory'], project_name ) )
			project_config_settings = YAML.load_file( File.join( config_settings['local_project_directory'], project_name, '.obi', 'config' ) )

			if project_config_settings['enable_rsync'] == 1 and project_config_settings["#{origin}_ssh"] != 0
				project_config_settings['rsync_dirs'].each do |dir|

					sync_cmd = "rsync -rvuz --exclude-from=\"#{ File.join config_settings['local_project_directory'], project_name }/.obiignore\" \"#{self.ssh( project_name, origin )}#{self.root( project_name, origin )}#{dir}\" \"#{self.ssh( project_name, destination )}#{self.root( project_name, destination )}#{dir}\""

					Open3.popen2e(sync_cmd) do |stdin, stdout_err, wait_thr|
						exit_status = wait_thr.value
						while line = stdout_err.gets
							puts "obi: #{line}"
						end
						unless exit_status.success?
								abort "obi: command failed - #{sync_cmd}"
						end
					end
				end
			else
				puts "\nobi: In order to rsync directories it must first be enabled this for this project by editing the \033[33m.obi/config\033[0m file in your project directory\n\n"
			end
		end

		def self.ssh( project_name, credintial )
			config_settings = Configuration.settings
			project_config_settings = YAML.load_file( File.join( config_settings['local_project_directory'], project_name, '.obi', 'config' ) )
			case credintial
			when 'local'
				return ''
			when 'staging'
				return "#{project_config_settings['staging_ssh']}:"
			when 'production'
				return "#{project_config_settings['production_ssh']}:"
			end
		end

		def self.root( project_name, credintial )
			config_settings = Configuration.settings
			project_config_settings = YAML.load_file( File.join( config_settings['local_project_directory'], project_name, '.obi', 'config' ) )
			case credintial
			when 'local'
				return File.join config_settings['local_project_directory'], project_name
			when 'staging'
				return project_config_settings['staging_remote_project_root']
			when 'production'
				return project_config_settings['production_remote_project_root']
			end
		end
	end
end





