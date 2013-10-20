require 'Thor'
require 'obi/Version'
require 'obi/Menu'
require 'obi/Project'
require 'obi/obi_module'

module Obi
	class Controller < Thor
		include Thor::Actions
		include Obi::Version
		include Obi::GetCurrentDirectory

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

		desc "database [option] [project_name]", "Backup a projects database by passing a project name"

		method_option :local, :aliases => "-l", :type => :boolean, :desc => "Local"
		method_option :staging, :aliases => "-s", :type => :boolean, :desc => "Staging"
		method_option :production, :aliases => "-p", :type => :boolean, :desc => "Production"
		method_option :to, :aliases => "-t", :type => :boolean, :desc => "Direction"
		method_option :import, :aliases => "-i", :type => :boolean, :desc => "Import into database"

		# method_option :local_to_staging, :aliases => "-ls", :type => :boolean, :desc => "Local to staging"
		# method_option :local_to_production, :aliases => "-lp", :type => :boolean, :desc => "Local to production"
		# method_option :staging_to_local, :aliases => "-sl", :type => :boolean, :desc => "Staging to local"
		# method_option :staging_to_production, :aliases => "-sp", :type => :boolean, :desc => "Staging to production"
		# method_option :production_to_local, :aliases => "-pl", :type => :boolean, :desc => "Production to local"
		# method_option :production_to_staging, :aliases => "-ps", :type => :boolean, :desc => "Production to staging"

		def database(project_name)
			project_name = get_current_directory_basename(project_name)
			if options.one?
				if options[:local]
					credentials = Obi::Environment.new.environment_settings('local', project_name)
					database = Obi::Database.new(project_name, credentials)
					database.dump
				elsif options[:staging]
					credentials = Obi::Environment.new.environment_settings('staging', project_name)
					database = Obi::Database.new(project_name, credentials)
					database.dump
				elsif options[:production]
					puts options[:production]
				elsif options[:import]
					puts options[:import]
				else
					puts
					puts "obi: The -t --to option can not be passed as the first argument"
					puts
				end
			else
				if options[:local]
					puts options[:local]
				elsif options[:staging]
					puts options[:staging]
				elsif options[:production]
					puts options[:production]
				elsif options[:import]
					puts options[:import]
				else
					puts
					puts "obi: The -t --to option can not be passed as the first argument"
					puts
				end
			end
		end
	end
end
