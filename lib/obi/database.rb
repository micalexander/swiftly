# require 'time'

module Obi
	class Database

		attr_accessor :mysql_special_characters, :sql_path, :sql_file, :credentials, :timestamp, :local_config_settings, :ssh_status, :ssh_user

		def initialize(project_name, credentials)
            @config_settings = Obi::Configuration.settings
            @project_name = project_name
			@mysql_special_characters = ['*', '?', '[', '<', '>', '&', ';', '!', '|', '$', '(', ')']
			escape_special_characters(credentials[:pass])
			@credentials = credentials
			@timestamp = Time.new.strftime("%F-%H-%M-%S")
            @sql_path = File.join( @config_settings['local_project_directory'], @project_name, "_resources", "dumps", @credentials[:environment] )
			@project_config_settings = YAML.load_file(File.join(@config_settings['local_project_directory'], @project_name, '.obi', 'config')) unless defined? @project_config_settings
			@ssh_status = @project_config_settings["enable_#{@credentials[:environment]}_ssh_sql"]
			@ssh_user = @project_config_settings["#{@credentials[:environment]}_ssh"]
        end

		def dump
			if @credentials[:environment] != "local" and @ssh_status != 0
				`ssh -C #{@ssh_user} mysqldump --single-transaction --opt --net_buffer_length=75000 --verbose \
				-u"#{@credentials[:user]}" -p"#{@credentials[:pass]}" "#{@credentials[:name]}" >  "#{@sql_path}/#{@timestamp}-#{@credentials[:environment]}.sql"`
			else
				`mysqldump --verbose -u"#{@credentials[:user]}" -h"#{@credentials[:host]}" -p#{@credentials[:pass]} \
				"#{@credentials[:name]}" >  "#{@sql_path}/#{@timestamp}-#{@credentials[:environment]}.sql"`
			end
		end

		def import(sql_file)
			@sql_file = sql_file
			if @credentials[:environment] != "local" and @ssh_status != 0
				`ssh -C #{@ssh_user} mysql -u"#{@credentials[:user]}" -p"#{@credentials[:pass]}" "#{@credentials[:name]}" < "#{@sql_file}"`
			else
				`mysql -u"#{@credentials[:user]}" -h"#{@credentials[:host]}" -p#{@credentials[:pass]} "#{@credentials[:name]}" < "#{@sql_file}"`
			end
		end

		def sync

		end

		def create
			`mysql -u"#{@credentials[:user]}" -h"#{@credentials[:host]}" -p#{@credentials[:pass]} -Bse "CREATE DATABASE #{@credentials[:name]}"`
		end

		def drop
			`mysql -u"#{@credentials[:user]}" -h"#{@credentials[:host]}" -p#{@credentials[:pass]} -Bse "DROP DATABASE #{@credentials[:name]}"`
		end

		def escape_special_characters(string)
			for i in @mysql_special_characters
				string.gsub!(Regexp.new(Regexp.escape(i))) { "\\#{i}" }
			end
			return string
		end
	end
end