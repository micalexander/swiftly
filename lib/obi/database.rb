# require 'time'

module Obi
	class Database

		include FindAndReplace

		attr_accessor :project_config_settings, :mysql_special_characters, :sql_path, :sql_file_path, :origin_credentials, :destination_credentials, :timestamp, :local_config_settings, :ssh_status, :ssh_user

		def initialize(project_name, origin_credentials = nil, destination_credentials = nil)
            @config_settings = Obi::Configuration.settings
            @project_name = project_name
			@mysql_special_characters = ['*', '?', '[', '<', '>', '&', ';', '!', '|', '$', '(', ')']
            origin_credentials[:pass] = escape_special_characters(origin_credentials[:pass])
            if destination_credentials
	            destination_credentials[:pass] = escape_special_characters(destination_credentials[:pass])
	            @destination_credentials = destination_credentials
			end
            @origin_credentials = origin_credentials
			@timestamp = Time.new.strftime("%F-%H-%M-%S")
            @sql_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", @origin_credentials[:environment] )
			@project_config_settings = YAML.load_file(File.join(@config_settings['local_project_directory'], @project_name, '.obi', 'config')) unless defined? @project_config_settings
			@ssh_status = @project_config_settings["enable_#{@destination_credentials[:environment]}_ssh_sql"]
			@ssh_user = @project_config_settings["#{@destination_credentials[:environment]}_ssh"]
        end

		def dump(credentials = @origin_credentials)
			sql_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", credentials[:environment] )
			ssh_status = @project_config_settings["enable_#{credentials[:environment]}_ssh_sql"]
			ssh_user = @project_config_settings["#{credentials[:environment]}_ssh"]
			if credentials[:environment] != "local" and ssh_status != 0
				`ssh -C #{ssh_user} mysqldump --single-transaction --opt --net_buffer_length=75000 --verbose \
				-u"#{credentials[:user]}" -p"#{credentials[:pass]}" "#{credentials[:name]}" >  "#{sql_path}/#{@timestamp}-#{credentials[:environment]}.sql"`
			else
				`mysqldump --verbose -u"#{credentials[:user]}" -h"#{credentials[:host]}" -p#{credentials[:pass]} \
				"#{credentials[:name]}" >  "#{sql_path}/#{@timestamp}-#{credentials[:environment]}.sql"`
			end
		end

		def import(sql_file_path)
			dump(@destination_credentials)
			@sql_file_path = sql_file_path
			update_urls
			if @destination_credentials[:environment] != "local" and @ssh_status != 0
				`ssh -C #{@ssh_user} mysql -u"#{@destination_credentials[:user]}" -p"#{@destination_credentials[:pass]}" "#{@destination_credentials[:name]}" < "#{@sql_file_path}"`
			else
				`mysql -u"#{@destination_credentials[:user]}" -h"#{@destination_credentials[:host]}" -p#{@destination_credentials[:pass]} "#{@destination_credentials[:name]}" < "#{@sql_file_path}"`
			end
		end

		def sync
			dump
			import(get_last_modified(@sql_path))
		end

		def create
			`mysql -u"#{@origin_credentials[:user]}" -h"#{@origin_credentials[:host]}" -p#{@origin_credentials[:pass]} -Bse "CREATE DATABASE #{@origin_credentials[:name]}"`
		end

		def drop
			`mysql -u"#{@origin_credentials[:user]}" -h"#{@origin_credentials[:host]}" -p#{@origin_credentials[:pass]} -Bse "DROP DATABASE #{@origin_credentials[:name]}"`
		end

		def update_urls
			temp_file_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(@sql_file_path))
            FileUtils.cp(@sql_file_path, File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", "temp", File.basename(@sql_file_path)))
			find_and_replace(input: temp_file_path, pattern: @origin_credentials[:site], output: "#{@destination_credentials[:site]}", file: true )
			@sql_file_path = temp_file_path
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

		def escape_special_characters(string)
			for i in @mysql_special_characters
				string.gsub!(Regexp.new(Regexp.escape(i))) { "\\#{i}" }
			end
			return string
		end
	end
end