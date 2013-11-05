require 'Thor'
require 'obi/configuration'
require 'obi/Menu'
require 'obi/Project'
require 'obi/obify'
require 'obi/obi_module'


module Obi
	class CLI < Thor
		include Thor::Actions
		include Obi::GetCurrentDirectoryBasename
		include Obi::ProjectExist

		# Handles the creation of the .obiconfig file
		desc "config", "Configure obi. (mandatory for first time and future use)"
		def config
			Configuration.check
			Menu.new.launch!
		end

		desc "upgrade", "Upgrade obi to the current version"

		method_option :project, :aliases => "-p", :type => :boolean, :desc => "Upgrade project config"
		method_option :global, :aliases => "-g", :type => :boolean, :desc => "Upgrade global config"
		method_option :all, :aliases => "-a", :type => :boolean, :desc => "Upgrade both global and project configs"

		def upgrade( project_name = nil )

			if options[:project] and !options[:all] and !options[:global]
				if project_name
					project_config = File.join( Configuration.settings['local_project_directory'], project_name, '.obi', 'config' )
					if YAML.load_file( project_config )['enable_production_ssh'] != 'enable_production_ssh'
						say
						say  "obi: #{project_name} is already up to date."
						say
					else
						project? File.join( Configuration.settings['local_project_directory'], project_name )
						Obify.project_config project_config
						say
						say  "obi: #{project_name} has been successfully updated."
						say
					end
				else
					say
					say "obi: Please provide a project name to upgrade"
					say
					exit
				end
			elsif options[:all] and !options[:project] and !options[:global]
				projects = Dir.glob(File.join( Configuration.settings['local_project_directory'],'*' )).select {|f| File.directory? f}
				projects.each do |project|
					project_config = File.join( project, '.obi', 'config' )
					if YAML.load_file( project_config )['enable_production_ssh'] != 'enable_production_ssh'
						say
						say  "obi: #{project_name} is already up to date."
						say
					else
						project? File.join( project )
						Obify.project_config project_config
						say
						say "obi: #{project} has been successfully updated."
					end
				end
				global_config = Configuration.global_file
				if File.exists? global_config
					if Configuration.settings['version'] != 'version'
						say
						say "obi: You already have the latest version"
						say
					else
						Obify.global_config global_config
						say
						say "obi: obi has been successfully updated."
						say
					end
				else
					say
					say "obi: There is nothing to upgrade please run [ obi config ] to get started"
					say
					exit
				end
			elsif options[:global] and !options[:all] and !options[:project]
				global_config = Configuration.global_file
				if File.exists? global_config
					if Configuration.settings['version'] != 'version'
						say
						say "obi: You already have the latest version"
						say
					else
						Obify.global_config global_config
						say
						say "obi: obi has been successfully updated."
						say
					end
				else
					say
					say "obi: Couldn't find a global config file, run [ obi config ] to get started"
					say
					exit
				end
			else
				say
				say "obi: Not sure what you are trying to do";
				say
				say `bin/obi3 -h upgrade`
				say
			end
		end

		desc "new [option] [project_name]", "Create a new projects by passing a project name"

		method_option :empty, :aliases => "-e", :type => :boolean, :desc => "Create an empty project"
		method_option :git, :aliases => "-g", :type => :boolean, :desc => "Create a Git enabled project"
		method_option :wordpress, :aliases => "-w", :type => :boolean, :desc => "Create a project with Wordpress installed"

		def new(project_name)

            Obi::Configuration.settings
			project = Obi::Project.new(project_name)
			if options.one?
				if options[:empty]
					project.empty
				elsif options[:git]
					project.git
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

		desc "destroy [option] [project_name]", "Remove a projects by passing a project name"

		def kill(project_name)

			database = Database.new(project_name)
			credentials = Environment.new

			database.dump( credentials.environment_settings( project_name, "local" ) )
			database.drop( credentials.environment_settings( project_name, "local" ) )

		 	directory = File.join( Configuration.settings['local_project_directory'], project_name + '/' )
		 	zipfile_name = File.join( Configuration.settings['local_project_directory'], project_name + '.zip' )

		 	if File.exist? zipfile_name

			 	puts ""
			 	puts "obi: Can't zip directory. There is already a zip file named [ #{project_name}.zip ]"
			 	puts ""
			 	exit

		 	else

				Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
				    Dir[File.join(directory, '**', '**')].each do |file|
				      zipfile.add(file.sub(directory, ''), file)
				    end
				end
				FileUtils.remove_dir( File.join( Configuration.settings['local_project_directory'], project_name ))
			end
		end

		no_tasks do
			alias_method :k, :kill
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
				say `bin/obi3 -h database`
				say
			end
		end
		no_tasks do
			alias_method :d, :database
		end

	end
end
