# require 'time'

module Obi
	class Database

		include FindAndReplace

		attr_accessor :project_config_settings, :sql_path, :timestamp, :local_config_settings

		def initialize(project_name)
            @config_settings = Obi::Configuration.settings
            @project_name = project_name
			@timestamp = Time.new.strftime("%F-%H-%M-%S")
			@project_config_settings = YAML.load_file(File.join(@config_settings['local_project_directory'], @project_name, '.obi', 'config')) unless defined? @project_config_settings
        end

		def dump(origin_credentials)
			origin_credentials[:pass] = escape_special_characters(origin_credentials[:pass])
			sql_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", origin_credentials[:environment] )
			ssh_status = @project_config_settings["enable_#{origin_credentials[:environment]}_ssh_sql"]
			ssh_user = @project_config_settings["#{origin_credentials[:environment]}_ssh"]
			if origin_credentials[:environment] != "local" and ssh_status != 0
				`ssh -C #{ssh_user} mysqldump --single-transaction --opt --net_buffer_length=75000 --verbose \
				-u"#{origin_credentials[:user]}" -p"#{origin_credentials[:pass]}" "#{origin_credentials[:name]}" >  "#{sql_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql"`
			else
				`mysqldump --verbose -u"#{origin_credentials[:user]}" -h"#{origin_credentials[:host]}" -p#{origin_credentials[:pass]} \
				"#{origin_credentials[:name]}" >  "#{sql_path}/#{@timestamp}-#{origin_credentials[:environment]}.sql"`
			end
		end

		def import(destination_credentials, import_file)
			destination_credentials[:pass] = escape_special_characters(destination_credentials[:pass])
			ssh_status = @project_config_settings["enable_#{destination_credentials[:environment]}_ssh_sql"]
			ssh_user = @project_config_settings["#{destination_credentials[:environment]}_ssh"]
			if destination_credentials[:environment] != "local" and ssh_status != 0
				`ssh -C #{ssh_user} mysql -u"#{destination_credentials[:user]}" -p"#{destination_credentials[:pass]}" "#{destination_credentials[:name]}" < "#{import_file}"`
			else
				`mysql -u"#{destination_credentials[:user]}" -h"#{destination_credentials[:host]}" -p#{destination_credentials[:pass]} "#{destination_credentials[:name]}" < "#{import_file}"`
			end
		end

		def sync(origin_credentials, destination_credentials, import_file = nil)
			dump(destination_credentials)
			dump(origin_credentials)
			if import_file == nil
				import_file = get_last_modified(File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", destination_credentials[:environment]))
			end
			import( destination_credentials, update_urls( origin_credentials, destination_credentials, import_file ))
		end

		def create(create_credentials)
			create_credentials[:pass] = escape_special_characters(create_credentials[:pass])
			`mysql -u"#{create_credentials[:user]}" -h"#{create_credentials[:host]}" -p#{create_credentials[:pass]} -Bse "CREATE DATABASE #{create_credentials[:name]}"`
		end

		def drop(drop_credentials)
			drop_credentials[:pass] = escape_special_characters(drop_credentials[:pass])
			`mysql -u"#{drop_credentials[:user]}" -h"#{drop_credentials[:host]}" -p#{drop_credentials[:pass]} -Bse "DROP DATABASE #{drop_credentials[:name]}"`
		end

		def update_urls( origin_credentials, destination_credentials, import_file )
            FileUtils.cp(import_file, File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(import_file)))
			temp_file_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(import_file))
			return find_and_replace(input: temp_file_path, pattern: origin_credentials[:site], output: "#{destination_credentials[:site]}", file: true )
		end

		def fix_serialization

		end

		def get_last_modified(dir)
			files = Dir.new(dir).select { |file| file!= '.' && file!='..' }
			return nil if (files.size < 1)
			files = files.collect { |file| dir+'/'+file }
			files = files.sort { |a,b| File.mtime(b)<=>File.mtime(a) }
			return files.first
		end

		def escape_special_characters(pass)
			for i in ['*', '?', '[', '<', '>', '&', ';', '!', '|', '$', '(', ')']
				if pass.include? i
					pass.gsub!(Regexp.new(Regexp.escape(i))) { "\\#{i}" }
				end
			end
			return pass
		end
	end
end