require 'obi/obi_module'
require 'open3'

module Obi
	class Database

		include FindAndReplace
		include FixSerialization
		include ProjectExist
		include LastModifiedDir

		attr_accessor :project_config_settings, :sql_path, :timestamp, :local_config_settings

		def initialize(project_name)

			@config_settings = Configuration.settings
			@project_name    = project_name
			@timestamp       = Time.new.strftime("%F-%H-%M-%S")

			project?( File.join(@config_settings['local_project_directory'], @project_name ) )

			@project_config_settings = YAML.load_file(
				File.join(
					@config_settings['local_project_directory'],
					@project_name,
					'.obi',
					'config'
				)
			) unless defined? @project_config_settings

    end

		def dump( origin_credentials )

			# provide the create dump site for the database dump
			dump_path = File.join(
				@config_settings['local_project_directory'],
				@project_name,
				"_resources",
				"dumps",
				origin_credentials[:environment]
			)

			# get the ssh_status and ssh_user(ssh alias) from the project specific config
			ssh_status = @project_config_settings["enable_#{origin_credentials[:environment]}_ssh_sql"]
			ssh_user   = @project_config_settings["#{origin_credentials[:environment]}_ssh"]

			# check if the origin_credentials environment provided was local and the ssh_status is set in order to dump using ssh or not
			if origin_credentials[:environment] != "local" and ssh_status != 0

				dump_cmd = "ssh \
					-C #{ssh_user} \
					mysqldump \
					--single-transaction \
					--opt \
					--net_buffer_length=75000 \
					--verbose \
					-u\'#{origin_credentials[:user]}\' \
					-h\'#{origin_credentials[:host]}\' \
					-p\'#{origin_credentials[:pass]}\' \
					\'#{origin_credentials[:name]}\' > \
					\"#{dump_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql\""

			else

				dump_cmd = "mysqldump \
				  --single-transaction \
				  --opt --net_buffer_length=75000 \
				  --verbose \
				  -u\'#{origin_credentials[:user]}\' \
				  -h\'#{origin_credentials[:host]}\' \
				  -p\'#{origin_credentials[:pass]}\' \
					\'#{origin_credentials[:name]}\' > \
					\"#{dump_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql\""

			end

			Open3.popen2e(dump_cmd) do |stdin, stdout_err, wait_thr|

				exit_status = wait_thr.value

				while line  = stdout_err.gets

					puts "obi: #{line}"

				end

				unless exit_status.success?

					abort "obi: command failed - #{dump_cmd}"

				end
			end
		end

		def import(destination_credentials, import_file)

			# get the ssh_status and ssh_user(ssh alias) from the project specific config
			ssh_status = @project_config_settings["enable_#{destination_credentials[:environment]}_ssh_sql"]
			ssh_user   = @project_config_settings["#{destination_credentials[:environment]}_ssh"]

			# check if the destination_credentials environment provided was local and the ssh_status is set in order to dump using ssh or not
			if destination_credentials[:environment] != "local" and ssh_status != 0

				import_cmd = "ssh \
					-C #{ssh_user} \
					mysql \
					-u\'#{destination_credentials[:user]}\' \
					-h\'#{destination_credentials[:host]}\' \
					-p\'#{destination_credentials[:pass]}\' \
					\'#{destination_credentials[:name]}\' \
					< \"#{import_file}\""

			else

				import_cmd = "mysql \
					-u\'#{destination_credentials[:user]}\' \
					-h\'#{destination_credentials[:host]}\' \
					-p\'#{destination_credentials[:pass]}\' \
					\'#{destination_credentials[:name]}\' < \
					\"#{import_file}\""

			end

			Open3.popen2e(import_cmd) do |stdin, stdout_err, wait_thr|

				exit_status = wait_thr.value

				while line  = stdout_err.gets

					puts "obi: #{line}"

				end

				unless exit_status.success?

					abort "obi: command failed - #{import_cmd}"

				end
			end
		end

		def sync(origin_credentials, destination_credentials, import_file = nil)

			# dump the destination database first!
			dump(destination_credentials)

			# dump the origin database
			dump(origin_credentials)

			# check to see if a file was provided, if not set pass the last modified file in the destination_credentials environment directory to be imported
			if import_file == nil

				import_file = get_last_modified(
					File.join(
						@config_settings['local_project_directory'],
						@project_name,
						"_resources",
						"dumps",
						origin_credentials[:environment]
					)
				)

			end

			import(
				destination_credentials, fix_serialization(
					update_urls(
						origin_credentials, destination_credentials, import_file
					)
				)
			)

		end

		def create(create_credentials)

			create_cmd = "mysql \
				-u\'#{create_credentials[:user]}\' \
				-h\'#{create_credentials[:host]}\' \
				-p\'#{create_credentials[:pass]}\' \
				-Bse\"CREATE DATABASE IF NOT EXISTS \
				#{create_credentials[:name]}\""

			Open3.popen2e(create_cmd) do |stdin, stdout_err, wait_thr|

				exit_status = wait_thr.value

				while line  = stdout_err.gets

					puts "obi: #{line}"

				end

				unless exit_status.success?

					abort "obi: command failed - #{create_cmd}"

				end
			end
		end

		def drop(drop_credentials)

			drop_cmd = "mysql \
				-u\'#{drop_credentials[:user]}\' \
				-h\'#{drop_credentials[:host]}\' \
				-p\'#{drop_credentials[:pass]}\' \
				-Bse\"DROP DATABASE IF EXISTS \
				#{drop_credentials[:name]}\""

			Open3.popen2e(drop_cmd) do |stdin, stdout_err, wait_thr|

				exit_status = wait_thr.value

				while line  = stdout_err.gets

					puts "obi: #{line}"
				end

				unless exit_status.success?

					abort "obi: command failed - #{drop_cmd}"

				end
			end
		end

		def update_urls( origin_credentials, destination_credentials, import_file )

			# copy the file to the temp folder
			FileUtils.cp(
				import_file,
				File.join(
					@config_settings['local_project_directory'],
					@project_name,
					"_resources",
					"dumps",
					"temp",
					File.basename(import_file)
				)
			)

      # set temp_file to that file to be rewritten
			temp_file = File.join(
				@config_settings['local_project_directory'],
				@project_name,
				"_resources",
				"dumps",
				"temp",
				File.basename(import_file)
			)

			# return the rewritten file
			return find_and_replace(
				input:   temp_file,
				pattern: origin_credentials[:site],
				output:  "#{destination_credentials[:site]}",
				file:    true
			)

		end
	end
end