require 'obi/obi_module'

module Obi
	class Database

		include FindAndReplace
		include FixSerialization
		include ProjectExist

		attr_accessor :project_config_settings, :sql_path, :timestamp, :local_config_settings

		def initialize(project_name)
            @config_settings = Configuration.settings
            @project_name = project_name
			@timestamp = Time.new.strftime("%F-%H-%M-%S")
			project?( File.join(@config_settings['local_project_directory'], @project_name ) )
			@project_config_settings = YAML.load_file( File.join( @config_settings['local_project_directory'], @project_name, '.obi', 'config' ) ) unless defined? @project_config_settings
        end

		def dump( origin_credentials )

			# escape the origin_credentials password
			origin_credentials[:pass] = escape_special_characters(origin_credentials[:pass])

			# provide the create dump site for the database dump
			dump_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", origin_credentials[:environment] )

			# get the ssh_status and ssh_user(ssh alias) from the project specific config
			ssh_status = @project_config_settings["enable_#{origin_credentials[:environment]}_ssh_sql"]
			ssh_user = @project_config_settings["#{origin_credentials[:environment]}_ssh"]

			# check if the origin_credentials environment provided was local and the ssh_status is set in order to dump using ssh or not
			if origin_credentials[:environment] != "local" and ssh_status != 0
				`ssh -C #{ssh_user} mysqldump --single-transaction --opt --net_buffer_length=75000 --verbose \
				-u"#{origin_credentials[:user]}" -p"#{origin_credentials[:pass]}" "#{origin_credentials[:name]}" >  "#{dump_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql"`
			else
				`mysqldump --verbose -u"#{origin_credentials[:user]}" -h"#{origin_credentials[:host]}" -p#{origin_credentials[:pass]} \
				"#{origin_credentials[:name]}" >  "#{dump_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql"`
			end
		end

		def import(destination_credentials, import_file)

			# escape the destination_credentials password
			destination_credentials[:pass] = escape_special_characters(destination_credentials[:pass])

			# get the ssh_status and ssh_user(ssh alias) from the project specific config
			ssh_status = @project_config_settings["enable_#{destination_credentials[:environment]}_ssh_sql"]
			ssh_user = @project_config_settings["#{destination_credentials[:environment]}_ssh"]

			# check if the destination_credentials environment provided was local and the ssh_status is set in order to dump using ssh or not
			if destination_credentials[:environment] != "local" and ssh_status != 0
				`ssh -C #{ssh_user} mysql -u"#{destination_credentials[:user]}" -p"#{destination_credentials[:pass]}" "#{destination_credentials[:name]}" < "#{import_file}"`
			else
				`mysql -u"#{destination_credentials[:user]}" -h"#{destination_credentials[:host]}" -p#{destination_credentials[:pass]} "#{destination_credentials[:name]}" < "#{import_file}"`
			end
		end

		def sync(origin_credentials, destination_credentials, import_file = nil)

			# dump the destination database first!
			dump(destination_credentials)

			# dump the origin database
			dump(origin_credentials)

			# check to see if a file was provided, if not set pass the last modified file in the destination_credentials environment directory to be imported
			if import_file == nil
				import_file = get_last_modified(File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", origin_credentials[:environment]))
			end

			import( destination_credentials, fix_serialization( update_urls( origin_credentials, destination_credentials, import_file ) ) )
		end

		def create(create_credentials)

			# escape the create_credentials password
			create_credentials[:pass] = escape_special_characters(create_credentials[:pass])
			`mysql -u"#{create_credentials[:user]}" -h"#{create_credentials[:host]}" -p#{create_credentials[:pass]} -Bse "CREATE DATABASE IF NOT EXISTS #{create_credentials[:name]}"`
		end

		def drop(drop_credentials)

			# escape the drop_credentials password
			drop_credentials[:pass] = escape_special_characters(drop_credentials[:pass])
			`mysql -u"#{drop_credentials[:user]}" -h"#{drop_credentials[:host]}" -p#{drop_credentials[:pass]} -Bse "DROP DATABASE IF EXISTS #{drop_credentials[:name]}"`
		end

		def update_urls( origin_credentials, destination_credentials, import_file )

			# copy the file to the temp folder
            FileUtils.cp(import_file, File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(import_file)))

            # set temp_file to that file to be rewritten
			temp_file = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(import_file))

			# return the rewritten file
			return find_and_replace(input: temp_file, pattern: origin_credentials[:site], output: "#{destination_credentials[:site]}", file: true )
		end

		def get_last_modified(dir)

			# make sure the files to be checked are in the provided directory
			files = Dir.new(dir).select { |file| file!= '.' && file!='..' }

			# make sure the file has been written to
			return nil if (files.size < 1)

			# create an array of all the files
			files = files.collect { |file| dir+'/'+file }

			# sort array by last modified
			files = files.sort { |a,b| File.mtime(b)<=>File.mtime(a) }

			# return the last modified file
			return files.first
		end

		def escape_special_characters(pass)

			# provide an array of special characters
			for character in ['*', '?', '[', '<', '>', '&', ';', '!', '|', '$', '(', ')']

				# check to see if the variable pass contains a special character
				if pass.include? character

					# escape each character found in the variable pass
					pass.gsub!(Regexp.new(Regexp.escape(character))) { "\\#{character}" }
				end
			end

			# return pass
			return pass
		end
	end
end