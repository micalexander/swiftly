require 'Thor'
require 'obi/configuration'
require 'obi/Menu'
require 'obi/Project'
require 'obi/obi_module'


module Obi
	class CLI < Thor
		include Thor::Actions
		include Obi::GetCurrentDirectoryBasename

		# Handles the creation of the .obiconfig file
		desc "config", "Maintain configuration variables"
		def config
			Configuration.check
			Menu.new.launch!
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
		no_tasks do
			alias_method :n, :new
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


		def database( project_name, import_file = "" )

			database = Obi::Database.new( get_current_directory_basename(project_name) )

			# check to see if one of the options was backup
			if options.keys.count == 2 and options[:backup]

				# dump the specified database
				if options[:local]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					database.dump( origin_credentials )
				elsif options[:staging]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					database.dump( origin_credentials )
				elsif options[:production]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					database.dump( origin_credentials )
				else
					say
					say "obi: The --#{options.keys[0]} option can not be passed by itself"
					say
				end

			# check to see if one of the options was import and a file was provided
			elsif options.keys.count == 2 and options[:import] and !import_file.empty?

				# get the necessary database credentials
				if options[:local]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
				elsif options[:staging]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
				elsif options[:production]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
				end

				# dump the destination database first!
				database.dump(origin_credentials)

				# import the supplied file into the specified database
				database.import(destination_credentials, import_file)

			# checkt to see if one of the options was sync
			elsif options.keys.count == 2 and options[:sync]

				# get the necessary database credentials
				if options[:lts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
				elsif options[:ltp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
				elsif options[:stl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
				elsif options[:stp]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")
				elsif options[:ptl]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")
				elsif options[:pts]
					origin_credentials = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")
				end

				# check to see if a file was provided if so find and replace urls and import it
				if import_file.empty?
					database.sync( origin_credentials, destination_credentials )
				else
					database.sync( origin_credentials, destination_credentials, import_file )
				end
			else
				say
				say "obi: Not sure what you are trying to do";
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
