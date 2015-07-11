require 'Thor'
require 'json'
require 'obi/Obi_module'
require 'obi/templates_config'
require 'obi/plugins_config'
require 'obi/Configuration'
require 'obi/Menu'
require 'obi/Project'
require 'obi/post_type'
require 'obi/Upgrade'
require 'obi/Rsync'


module Obi
	class CLI < Thor

		include Thor::Actions
		include Obi::GetCurrentDirectoryBasename
		include Obi::ProjectExist


		# Handles the creation of the .obiconfig file
		desc "config", "Configure obi. (mandatory for first time and future use)"

		def config

			Upgrade.check
			Configuration.check
			Menu.new.launch!

		end

		desc "upgrade", "Upgrade obi to the current version"

		method_option :project, :aliases => "-p", :type => :boolean, :desc => "Upgrade project config"
		method_option :global , :aliases => "-g", :type => :boolean, :desc => "Upgrade global config"
		method_option :all    , :aliases => "-a", :type => :boolean, :desc => "Upgrade both global and project configs"

		def upgrade( project_name = nil )

			project_name = get_current_directory_basename(project_name)

			if options[:project] and !options[:all] and !options[:global]

				Upgrade.project_config project_name

			elsif options[:all] and !options[:project] and !options[:global]

				Upgrade.all

			elsif options[:global] and !options[:all] and !options[:project]

				Upgrade.global_config

			else

				say
				say "obi: Not sure what you are trying to do";
				say
				say `obi -h upgrade`
				say

			end
		end

		desc "plugins", "Create global plugin directory in working project directory"

		def plugins

			Upgrade.check
      Configuration.settings
     	PluginsConfig.new.create

		end

		desc "templates", "Create global template directory in working project directory"

		def templates

			Upgrade.check
			Configuration.settings
			TemplatesConfig.new.create

		end


		desc "new [option] [project_name]", "Create a new projects by passing a project name"

		method_option :empty    , :aliases => "-e", :type => :boolean, :desc => "Create an empty project"
		method_option :git      , :aliases => "-g", :type => :boolean, :desc => "Create a Git enabled project"
		method_option :wordpress, :aliases => "-w", :type => :boolean, :desc => "Create a project with Wordpress installed"
		method_option :dev      , :aliases => "-d", :type => :boolean, :desc => "If Wordpress option is used run bower and guard"

		def new(project_name, template = '')

			Upgrade.check

			project_name = get_current_directory_basename(project_name)

      Obi::Configuration.settings

			project = Obi::Project.new(project_name)

			if options.length == 1

				if options[:empty]

					project.empty

				elsif options[:git]

					project.git

				elsif options[:wordpress]

					project.wordpress template

				end

			elsif options.length == 2

				if options[:wordpress] && options[:dev]

					project.wordpress template, options[:dev]

				end

			else

				say
				say "obi: new expects at least one option"
				say

			end
		end

		no_tasks do

			alias_method :n, :new

		end

		desc "destroy [option] [project_name]", "Remove a projects by passing a project name"

		def kill(project_name)

			Upgrade.check

			project_name = get_current_directory_basename(project_name)
			database     = Database.new(project_name)
			credentials  = Environment.new

			database.dump( credentials.environment_settings( project_name, "local" ) )
			database.drop( credentials.environment_settings( project_name, "local" ) )

			directory    = File.join( Configuration.settings['local_project_directory'], project_name + '/' )
			zipfile_name = File.join( Configuration.settings['local_project_directory'], project_name + '.zip' )

		 	if File.exist? zipfile_name

			 	say ""
			 	say "obi: Can't zip directory. There is already a zip file named [ #{project_name}.zip ]"
			 	say ""
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

		method_option :backup    , :aliases => "-b"    , :type => :boolean, :desc => "Backup database"
		method_option :import    , :aliases => "-i"    , :type => :boolean, :desc => "Import file into database"
		method_option :sync      , :aliases => "-y"    , :type => :boolean, :desc => "Sync two databases"
		method_option :local     , :aliases => "-l"    , :type => :boolean, :desc => "Local"
		method_option :staging   , :aliases => "-s"    , :type => :boolean, :desc => "Staging"
		method_option :production, :aliases => "-p"    , :type => :boolean, :desc => "Production"
		method_option :lts       , :type    => :boolean, :desc => "Local to staging"
		method_option :ltp       , :type    => :boolean, :desc => "Local to production"
		method_option :stl       , :type    => :boolean, :desc => "Staging to local"
		method_option :stp       , :type    => :boolean, :desc => "Staging to production"
		method_option :ptl       , :type    => :boolean, :desc => "Production to local"
		method_option :pts       , :type    => :boolean, :desc => "Production to staging"


		def database( project_name, import_file = "" )

			Upgrade.check

			project_name = get_current_directory_basename(project_name)
			database     = Obi::Database.new( project_name )

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

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")

				elsif options[:staging]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")

				elsif options[:production]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "production")
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

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "staging")

				elsif options[:ltp]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "local")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")

				elsif options[:stl]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")

				elsif options[:stp]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "staging")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "production")

				elsif options[:ptl]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "production")
					destination_credentials = Obi::Environment.new.environment_settings(project_name, "local")

				elsif options[:pts]

					origin_credentials      = Obi::Environment.new.environment_settings(project_name, "production")
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
				say `obi -h database`
				say

			end
		end

		no_tasks do

			alias_method :d, :database

		end

		desc "rsync [option] [project_name]", "Mirror two directories by passing a project name, origin and destination"

		method_option :lts, :type => :boolean, :desc => "Local to staging"
		method_option :ltp, :type => :boolean, :desc => "Local to production"
		method_option :stl, :type => :boolean, :desc => "Staging to local"
		method_option :stp, :type => :boolean, :desc => "Staging to production"
		method_option :ptl, :type => :boolean, :desc => "Production to local"
		method_option :pts, :type => :boolean, :desc => "Production to staging"

		def rsync(project_name)

			Upgrade.check

			project_name = get_current_directory_basename(project_name)

      Obi::Configuration.settings

			if options.keys.count == 1

				# get the necessary database credentials
				if options[:lts]

					origin      = "local"
					destination = "staging"

				elsif options[:ltp]

					origin      = "local"
					destination = "production"

				elsif options[:stl]

					origin      = "staging"
					destination = "local"

				elsif options[:stp]

					origin      = "staging"
					destination = "production"

				elsif options[:ptl]

					origin      = "production"
					destination = "local"

				elsif options[:pts]

					origin      = "production"
					destination = "staging"

				end

				Rsync.sync project_name, origin, destination

			else

				say
				say "obi: Not sure what you are trying to do";
				say
				say `obi -h rsync`
				say

			end
		end

		no_tasks do

			alias_method :r, :rsync

		end

		desc "generate [option] [project_name] [post_type]", "Generate wordpress templates"

		method_option :custom_post_type, :aliases => "-c", :type => :boolean, :desc => "Generate custom post type"

		def generate( project_name, post_type, filter_by = '' )

			Upgrade.check

			project_name = get_current_directory_basename(project_name)

      Obi::Configuration.settings

			if options.keys.count == 1

				PostType.new([project_name, post_type, File.join( Configuration.settings['local_project_directory'], project_name)], {'filter_by' => "#{filter_by[/(.+[=])(.+)/, 2]}"}).invoke_all

			else

				say
				say "obi: Not sure what you are trying to do";
				say
				say `obi -h generate`
				say

			end
		end

		no_tasks do

			alias_method :g, :generate

		end
	end
end
