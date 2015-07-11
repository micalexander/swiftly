require 'obi/project_config'
require 'obi/plugins'
require 'obi/templates'
require 'fileutils'
require 'git'
require 'zip'
require 'obi/environment'
require 'obi/redirectfollower'
require 'obi/database'
require 'obi/obi_module'

module Obi
	class Project

		include Obi::FindAndReplace
		include Obi::FindAndReplaceAll
		include LastModifiedDir

		attr_accessor :project_path, :project_name


		def initialize(project_name)

			@config_settings = Obi::Configuration.settings
			@project_name    = project_name
			@project_path    = File.join(
				@config_settings['local_project_directory'],
				@project_name
			)

		end

		def create_directories

			if !File.directory?(@project_path)

				asset_path_str = "parent_folder/sub_dir/{ai,architecture,content,emails,estimates,fonts,gif,jpg,pdf,png,psd}"
				dumps_path_str = "parent_folder/sub_dir/{local,production,staging,temp}"
				asset_paths    = asset_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@project_path}/_resources/assets/" << s }
				dumps_paths    = dumps_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@project_path}/_resources/dumps/" << s }

				FileUtils.mkdir_p [asset_paths, dumps_paths], {:noop => false, :verbose => false}
				FileUtils.mkdir File.join(@project_path, ".obi"), {:noop => false, :verbose => false}
				ProjectConfig.new.create(@project_path)

				File.open(File.join(@project_path, ".obiignore"), "w") do |file|

						file.puts ".git\n.gitignore\n.htaccess\nsftp-config.json\n.DS_Store\n_resources\n.obi"
				end

			else

				puts ""
				puts "obi: There is already a project with the name \"#{@project_name}\". Please try again."
				puts ""
				exit

			end
		end

		def enable_git

				File.open(File.join( @project_path, ".gitignore"), "w") do |file|

					file.puts ".DS_Store\n.sass-cache/\n_resources/\n.obi/\n.obiignore\nbower_components/"

				end

				git = Git.init( @project_path )
				git.add
				git.commit_all('initial commit')

		end

		def empty

			create_directories

		end

		def git

			create_directories
			enable_git

		end

		def wordpress template, dev = false

			if ( template != '' )

				if ( !Templates.settings_check )

					abort "\nobi: to specify a template for obi to use, [ obi templates ] must be run first and \"_templates.yml\" file must be configured\n\n"

				end

			end

			create_directories

			# download wordpress and place it in the project directory
			wordpress = RedirectFollower.new('http://wordpress.org/latest.zip').resolve

			File.open(File.join( @project_path, "latest.zip"), "w") do |file|

					file.write wordpress.body

			end

			# unzip the wordpress zip file
			zipfile_name = File.join(@project_path, 'latest.zip')

			Zip::File.open(zipfile_name) do |zipfile|

					# entry is an instance of Zip::ZipEntry
					zipfile.each do |entry|

							entry_file_path = File.join(@project_path , entry.to_s)

							puts "\033[36mobi:\033[0m - #{@project_path}/#{entry}"

							zipfile.extract(entry, entry_file_path)
					end
			end

			# remove wordpress folder and zip file
			FileUtils.rm(File.join(@project_path, 'latest.zip'))

			FileUtils.mv( Dir[File.join(@project_path, 'wordpress/*')], @project_path )

			FileUtils.rmdir(File.join(@project_path, 'wordpress'))

			if template.empty?

					template_location = Templates.load_template
					template_name     = 'mask'

			else

					template_location = Templates.load_template template
					template_name     = template

			end

			if template_location =~ /^#{URI::regexp}$/

				# download the framwork
				downloaded_template = RedirectFollower.new(template_location).resolve

				File.open(File.join( @project_path, "wp-content", "themes", File.basename(template_location)), "w") do |file|

						file.write downloaded_template.body

				end

				# unzip the template zip file
				zipfile_name = File.join(
					@project_path,
					"wp-content",
					"themes",
					File.basename(template_location)
				)

				Zip::File.open(zipfile_name) do |zipfile|

					# entry is an instance of Zip::ZipEntry
					zipfile.each do |entry|

						entry_file_path = File.join(
							@project_path,
							"wp-content",
							"themes",
							entry.to_s
						)

						zipfile.extract(entry, entry_file_path)

					end
				end

				# remove folder and zippped file
				FileUtils.rm(File.join(
					@project_path,
					"wp-content",
					"themes",
					File.basename(template_location))
				)

				FileUtils.mv(
					get_last_modified(File.join(
						@project_path,
						"wp-content",
						"themes")
					),
					File.join(
					@project_path,
					"wp-content",
					"themes",
					"#{@project_name}")
				)

			else

					FileUtils.cp_r(File.join(@config_settings['local_project_directory'], '.obi', 'templates', template), File.join(@project_path, "wp-content", "themes", "#{@project_name}"))

			end

			theme_dir = File.join(@project_path, "wp-content", "themes", "#{@project_name}");

			# move the wp-config, .htaccess, bower.json, config.rb, Guardfile, Gemfile, and Gemfile.lock files to the site root
			FileUtils.mv(File.join(theme_dir, ".htaccess"), @project_path ) unless !File.exists?  File.join(theme_dir, ".htaccess")
			FileUtils.mv(File.join(theme_dir, "wp-config.php"), @project_path ) unless !File.exists? File.join(theme_dir, "wp-config.php")
			FileUtils.mv(File.join(theme_dir, "bower.json"), @project_path ) unless !File.exists? File.join(theme_dir, "bower.json")
			FileUtils.mv(File.join(theme_dir, "config.rb"), @project_path ) unless !File.exists? File.join(theme_dir, "config.rb")
			FileUtils.mv(File.join(theme_dir, "Guardfile"), @project_path ) unless !File.exists? File.join(theme_dir, "Guardfile")
			FileUtils.mv(File.join(theme_dir, "Gemfile"), @project_path ) unless !File.exists? File.join(theme_dir, "Gemfile")
			FileUtils.mv(File.join(theme_dir, "Gemfile.lock"), @project_path ) unless !File.exists? File.join(theme_dir, "Gemfile.lock")

			# remove sample wp-config
			FileUtils.rm(File.join(@project_path, "wp-config-sample.php"))

			# move site specific plugin to the plugins folder
			FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "#{template_name}-specific-plugin"), File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin")) unless !File.exists? File.join(@project_path, "wp-content", "themes", "#{@project_name}", "#{template_name}-specific-plugin")
			FileUtils.mv(File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin",  "#{template_name}-plugin.php"), File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php")) unless !File.exists? File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin",  "#{template_name}-plugin.php")

			# grab global plugins if they exist
			if Plugins.settings_check

				Dir.glob( File.join(@config_settings['local_project_directory'], '.obi', 'plugins', "**")).each do |dir|

					FileUtils.cp_r dir, File.join( @project_path, 'wp-content', 'plugins') unless !File.exist?( File.join(@config_settings['local_project_directory'], '.obi','plugins') )

				end
			end

			# add plugins to the functions file
			Plugins.add_plugins_to_functions_file @project_path

			# find and replace the #{template_name} name with the project name
			FileUtils.mv(
				File.join(@project_path, "wp-content", "themes", "#{@project_name}", "img", "wp-login-logo-#{template_name}.png"),
				File.join(@project_path, "wp-content", "themes", "#{@project_name}", "img", "wp-login-logo-#{@project_name}.png")
			) unless !File.exists? File.join(@project_path, "wp-content", "themes", "#{@project_name}", "img", "wp-login-logo-#{template_name}.png")

			site_specific_plugin_php = File.join(
				@project_path,
				"wp-content",
				"plugins",
				"#{@project_name}-specific-plugin",
				"#{@project_name}-plugin.php"
			)

			functions_php = File.join(
				@project_path,
				"wp-content",
				"themes",
				"#{@project_name}",
				"functions.php"
			)

			config_rb = File.join(
				@project_path,
				"config.rb"
			)

			guardfile = File.join(
				@project_path,
				"Guardfile"
			)

			ie_scss = File.join(
				@project_path,
				"wp-content",
				"themes",
				"#{@project_name}",
				"sass",
				"ie.scss"
			)

			wp_config_php = File.join(
				@project_path,
				"wp-config.php"
			)

			wp_config_db_settings = '{
				"name": "' + @project_name + '_local_wp",
				"host": "' + @config_settings['local_user'] + '",
				"user": "' + @config_settings['local_password'] + '",
				"pass": "' + @config_settings['local_host'] + '",
				"site": http://' + @project_name + '.dev",
				"home": http://' + @project_name + '.dev",
			}'

			if @config_settings['staging_domain'] == 0

					staging_url = "changeme.dev"

			else

					staging_url = @config_settings['staging_domain']

			end

			find_and_replace_all(
				[
					{
						input:   site_specific_plugin_php,
						pattern: /#{template_name}/,
						output:  "#{@project_name}",
						file:    true
					},
					{
						input:   site_specific_plugin_php,
						pattern: /(Plugin\s+Name:\s+)(#{@project_name})/,
						output:  "Plugin Name: #{@project_name.capitalize}",
						file:    true
					},
					{
						input:   site_specific_plugin_php,
						pattern: /(Description:\s+Site\s+specific\s+code\s+changes\s+for\s+)(#{@project_name})/,
						output:  "Description: Site specific code changes for #{@project_name.capitalize}",
						file:    true
					},
					{
						input:   functions_php,
						pattern: /#{template_name}/,
						output:  "#{@project_name}",
						file:    true
					},
					{
						input:   config_rb,
						pattern: /#{template_name}/,
						output:  "#{@project_name}",
						file:    true
					},
					{
						input:   guardfile,
						pattern: /#{template_name}/,
						output:  "#{@project_name}",
						file:    true
					},
					{
						input:   ie_scss,
						pattern: /themes\/#{template_name}/,
						output:  "themes/#{@project_name}",
						file:    true
					},
					{
						input:   wp_config_php,
						pattern: File.read(wp_config_php)[/\$local\s*?=[\s|\S]*?({[\s|\S]*?})/, 1],
						output:  wp_config_db_settings,
						file:    true
					},
					{
						input:   wp_config_php,
						pattern: /staging_tld/,
						output:  staging_url.gsub(/\./){ |match| "\\" + match  },
						file:    true
					},
					{
						input:   wp_config_php,
						pattern: /#{template_name}/,
						output:  "#{@project_name}",
						file:    true
					},
					{
						input:   wp_config_php,
						pattern: /\/\/\s*Insert_Salts_Below/,
						output:   Net::HTTP.get('api.wordpress.org', '/secret-key/1.1/salt'),
						file:    true
					},
					{
						input:   wp_config_php,
						pattern: /(table_prefix\s*=\s*')(wp_')/,
						output:  '\1' + @project_name[0,3] + "_'",
						file:    true
					},
				]
			)

			# Create project's database
			credentials = {
				host: 			 "#{@config_settings['local_host']}",
				user: 			 "#{@config_settings['local_user']}",
				pass: 			 "#{@config_settings['local_password']}",
				name: 			 "#{@project_name}_local_wp",
				environment: "local"
			}

			database = Obi::Database.new(@project_name)

			database.create(credentials)

			# enable git repository
			enable_git

			# puts @project_path
			if File.exists? File.join( @project_path, 'Gemfile' )

				bundle_cmd = "cd \"#{@project_path}\"; bundle;"

				Open3.popen2e(bundle_cmd) do |stdin, stdout_err, wait_thr|

					exit_status = wait_thr.value

					while line  = stdout_err.gets

							puts "obi: #{line}"

					end

					unless exit_status.success?

							abort "obi: command failed - #{bundle_cmd}"

					end
				end
			end

			if(File.exists?(File.join( @project_path, 'Gemfile' )) && dev)

				bower_cmd = "cd \"#{@project_path}\"; bower update;"

				Open3.popen2e(bower_cmd) do |stdin, stdout_err, wait_thr|

					exit_status = wait_thr.value

					while line  = stdout_err.gets

							puts "obi: #{line}"

					end

					unless exit_status.success?

							abort "obi: command failed - #{bower_cmd}"

					end
				end
			end

			# guard will keep obi running so we'll just shell it out here
			if(File.exists?(File.join( @project_path, 'Guardfile' )) && dev)

					`cd "#{@project_path}"; bundle exec guard;`

			end
		end
	end
end



