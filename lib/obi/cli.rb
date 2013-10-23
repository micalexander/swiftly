require 'Thor'
require 'obi/Version'
require 'obi/Menu'
require 'obi/Project'
require 'obi/obi_module'

module Obi
	class CLI < Thor
		include Thor::Actions
		include Obi::Version
		include Obi::GetCurrentDirectoryBasename

		# Handles the creation of the .obiconfig file
		desc "config", "Maintain configuration variables"
		def config
			if (!File.exist?( CONFIG_FILE_LOCATION ))
				File.open( CONFIG_FILE_LOCATION, 'w') do |file|
					file.puts VERSION
				end
			else
				menu = Obi::Menu.new
				menu.launch_menu!
			end
		end

		desc "new [option] [project_name]", "Create a new projects by passing a project name"

		method_option :empty, :aliases => "-e", :type => :boolean, :desc => "Create an empty project"
		method_option :git, :aliases => "-g", :type => :boolean, :desc => "Create a Git enabled project"
		method_option :wordpress, :aliases => "-w", :type => :boolean, :desc => "Create a project with Wordpress installed"

		def new(project_name)
			project = Obi::Project.new(project_name)
			if options.one?
				if options[:empty]
					# project.empty
				elsif options[:git]
					# project.git
				elsif options[:wordpress]
					project.wordpress
				end
			else
				puts
				puts "obi: new expects only one option"
				puts
			end
		end

		desc "database [option] [project_name]", "Maintain your databases by passing a project name"

		method_option :backup, :aliases => "-b", :type => :boolean, :desc => "Backup database"
		method_option :import, :aliases => "-i", :type => :boolean, :desc => "Import file into database"
		method_option :sync, :aliases => "-y", :type => :boolean, :desc => "Sync two databases"
		method_option :local, :aliases => "-l", :type => :boolean, :desc => "Local"
		method_option :staging, :aliases => "-s", :type => :boolean, :desc => "Staging"
		method_option :production, :aliases => "-p", :type => :boolean, :desc => "Production"
		method_option :lts, :type => :boolean, :desc => "Local to staging"
		method_option :ltp, :type => :boolean, :desc => "Local to production"
		method_option :stl, :type => :boolean, :desc => "Staging to local"
		method_option :stp, :type => :boolean, :desc => "Staging to production"
		method_option :ptl, :type => :boolean, :desc => "Production to local"
		method_option :pts, :type => :boolean, :desc => "Production to staging"


		def database(project_name, sql_file_path="")
			project_name = get_current_directory_basename(project_name)
			if options.keys.count == 2 and options[:backup]
				if options[:local]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, origin_credentials)
					database.dump
				elsif options[:staging]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, origin_credentials)
					database.dump
				elsif options[:production]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, origin_credentials)
					database.dump
				else
					say
					say "obi: The --#{options.keys[0]} option can not be passed by itself"
					say
				end
			elsif options.keys.count == 2 and options[:import] and !sql_file_path.empty?
				if options[:local]
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, destination_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:staging]
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, destination_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:production]
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, destination_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:lts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:ltp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:stl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:stp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:ptl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				elsif options[:pts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.import(sql_file_path)
				end
			elsif options.keys.count == 2 and options[:sync]
				if options[:lts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				elsif options[:ltp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				elsif options[:stl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				elsif options[:stp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				elsif options[:ptl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				elsif options[:pts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database = Obi::Database.new(project_name, origin_credentials, destination_credentials)
					database.sync
				end
			else
				say
				say "obi: I dont understand what you are trying to do";
				say
				say `lib/obi3 -h database`
				say
			end
		end
		no_tasks do
			alias_method :d, :database
		end

	end
end
