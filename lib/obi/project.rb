require 'obi/project_config'
require 'obi/plugins'
require 'net/http'
require 'fileutils'
require 'git'
require 'zip'
require 'obi/environment'
require 'obi/database'
require 'obi/obi_module'

module Obi
    class Project
        include Obi::FindAndReplace

        attr_accessor :project_path, :project_name

        class RedirectFollower
            class TooManyRedirects < StandardError; end

            attr_accessor :url, :body, :redirect_limit, :response

            def initialize(url, limit=5)
                @url, @redirect_limit = url, limit
            end

            def resolve
                raise TooManyRedirects if redirect_limit < 0

                self.response = Net::HTTP.get_response(URI.parse(url))

                if response.kind_of?(Net::HTTPRedirection)
                  self.url = redirect_url
                  self.redirect_limit -= 1

                  resolve
                end

                self.body = response.body
                self
            end

            def redirect_url
                if response['location'].nil?
                    response.body.match(/<a href=\"([^>]+)\">/i)[1]
                else
                    response['location']
                end
            end
        end

        def initialize(project_name)
            @config_settings = Obi::Configuration.settings
            @project_name = project_name
            @project_path = File.join( @config_settings['local_project_directory'], @project_name )

        end

        def create_directories
            if !File.directory?(@project_path)
                asset_path_str = "parent_folder/sub_dir/{ai,architecture,content,emails,estimates,fonts,gif,jpg,pdf,png,psd}"
                dumps_path_str = "parent_folder/sub_dir/{local,production,staging,temp}"
                asset_paths = asset_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@project_path}/_resources/assets/" << s }
                dumps_paths = dumps_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@project_path}/_resources/dumps/" << s }
                FileUtils.mkdir_p [asset_paths, dumps_paths], {:noop => false, :verbose => false}
                FileUtils.mkdir File.join(@project_path, ".obi"), {:noop => false, :verbose => false}
                ProjectConfig.new.create(@project_path)
                File.open(File.join( @project_path, ".obiignore"), "w") { |file| file.puts ".git\n.gitignore\n.htaccess\nsftp-config.json\n.DS_Store\n_resources\n.obi" }
            else
                puts ""
                puts "obi: There is already a project with the name \"#{@project_name}\". Please try again."
                puts ""
                exit
            end
        end

        def enable_git
            File.open(File.join( @project_path, ".gitignore"), "w") { |file| file.puts ".DS_Store\n.sass-cache/\n_resources/\n.obi/\n.obiignore\nbower_components/" }
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

        def wordpress

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
                    # FileUtils.mkdir_p(File.dirname(entry_file_path))
                    zipfile.extract(entry, entry_file_path)
                end
            end

            # remove wordpress folder and zip file
            FileUtils.rm(File.join(@project_path, 'latest.zip'))
            FileUtils.mv( Dir[File.join(@project_path, 'wordpress/*')], @project_path )
            FileUtils.rmdir(File.join(@project_path, 'wordpress'))

            # download the mask framwork
            # get_mask
            mask = RedirectFollower.new('https://github.com/micalexander/mask/archive/master.zip').resolve
            File.open(File.join( @project_path, "wp-content", "themes", "master.zip"), "w") do |file|
                file.write mask.body
            end

            # unzip the mask zip file
            zipfile_name = File.join(@project_path, "wp-content", "themes","master.zip")
            Zip::File.open(zipfile_name) do |zipfile|
                # entry is an instance of Zip::ZipEntry
                zipfile.each do |entry|
                    entry_file_path = File.join(@project_path, "wp-content", "themes", entry.to_s)
                    zipfile.extract(entry, entry_file_path)
                end
            end

            # remove mask folder and zip file
            FileUtils.rm(File.join(@project_path, "wp-content", "themes", "master.zip"))
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "mask-master"), File.join(@project_path, "wp-content", "themes", "#{@project_name}"))

            # move the wp-config, .htaccess, bower.json, Guardfile, Gemfile, and Gemfile.lock files to the site root
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", ".htaccess"), @project_path )
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "wp-config.php"), @project_path )
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "bower.json"), @project_path )
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "Guardfile"), @project_path )
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "Gemfile"), @project_path )
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "Gemfile.lock"), @project_path )

            # remove sample wp-config
            FileUtils.rm(File.join(@project_path, "wp-config-sample.php"))

            # move site specific plugin to the plugins folder
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "mask-specific-plugin"), File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin"))
            FileUtils.mv(File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin",  "mask-plugin.php"), File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php"))

            # grab global plugins if they exist
            if Plugins.settings_check
                Dir.glob( File.join(@config_settings['local_project_directory'], '.obi', 'plugins', "**")).each do |dir|
                    FileUtils.cp_r dir, File.join( @project_path, 'wp-content', 'plugins') unless !File.exist?( File.join(@config_settings['local_project_directory'], '.obi','plugins') )
                end
            end
            # add plugins to the functions file
            Plugins.add_plugins_to_functions_file @project_path

            # find and replace the mask name with the project name
            FileUtils.mv(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "img", "wp-login-logo-mask.png"), File.join(@project_path, "wp-content", "themes", "#{@project_name}", "img", "wp-login-logo-#{@project_name}.png"))


            # find and replace the mask name with the project name
            # - text to find and replace
            plugin_replace = File.read(File.join(@project_path, "wp-content", "plugins",
                "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php")).gsub(/mask/, "#{@project_name}")
            File.open(File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php"), "w") { |file|
                file.puts plugin_replace }

            plugin_second_replace = File.read(File.join(@project_path, "wp-content", "plugins",
                "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php")).gsub(/(Plugin\s+Name:\s+)(#{@project_name})/, "Plugin Name: #{@project_name.capitalize}")
            File.open(File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php"), "w") { |file|
                file.puts plugin_second_replace }

            plugin_third_replace = File.read(File.join(@project_path, "wp-content", "plugins",
                "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php")).gsub(/(Description:\s+Site\s+specific\s+code\s+changes\s+for\s+)(#{@project_name})/, "Description: Site specific code changes for #{@project_name.capitalize}")
            File.open(File.join(@project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin", "#{@project_name}-plugin.php"), "w") { |file|
                file.puts plugin_third_replace }

            function_replace = File.read(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "functions.php")).gsub(/mask/, "#{@project_name}")
            guard_replace = File.read(File.join(@project_path, "Guardfile")).gsub(/mask/, "#{@project_name}")
            ie_replace = File.read(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "sass", "ie.scss")).gsub(/themes\/mask/, "themes/#{@project_name}")
            # - open file and perform find and replace

            File.open(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "functions.php"), "w") { |file| file.puts function_replace }
            File.open(File.join(@project_path, "Guardfile"), "w") { |file| file.puts guard_replace }
            File.open(File.join(@project_path, "wp-content", "themes", "#{@project_name}", "sass", "ie.scss"), "w") { |file| file.puts ie_replace }

            # find and replace variables on wp-config file
            # - define WP_ENV variables
            find_config_value =  File.read( File.join( @project_path,
                    "wp-config.php"))[/\(\s*WP_ENV\s*==\s*'\s*local\s*'\s*\).*{[\s|\S]*?}/]
            replace_config_value =  File.read( File.join( @project_path,
                    "wp-config.php"))[/\(\s*WP_ENV\s*==\s*'\s*local\s*'\s*\).*{[\s|\S]*?}/]
            find_config_value.each_line do |line|
                find_config_value.gsub!(/(('|")\s*DB_NAME\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}#{@project_name}_local_wp#{$3}" }
                                 .gsub!(/(('|")\s*DB_USER\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}#{@config_settings['local_user']}#{$3}" }
                                 .gsub!(/(('|")\s*DB_PASSWORD\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}#{@config_settings['local_password']}#{$3}" }
                                 .gsub!(/(('|")\s*DB_HOST\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}#{@config_settings['local_host']}#{$3}" }
                                 .gsub!(/(('|")\s*WP_SITEURL\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}http://#{@project_name}.dev#{$3}" }
                                 .gsub!(/(('|")\s*WP_HOME\s*'\s*,\s*('|"))([\s|\S]*?)('|")/) { "#{$1}http://#{@project_name}.dev#{$3}" }
            end
            # - put the wp-config file in memory
            wp_config = File.read(File.join(@project_path, "wp-config.php"))
            # - find and replace remaining values on the the wp-config
            if @config_settings['staging_domain'] == 0
                staging_url = "changeme.dev"
            else
                staging_url = @config_settings['staging_domain']
            end
            wp_config.gsub!(/staging_tld/, staging_url.gsub(/\./){ |match| "\\" + match  })
                     .gsub!(/mask/, "#{@project_name}")
                     .gsub!(Regexp.new(Regexp.escape(replace_config_value)), "#{find_config_value}")
                     .gsub!(/\/\/\s*Insert_Salts_Below/, Net::HTTP.get('api.wordpress.org', '/secret-key/1.1/salt'))
                     .gsub!(/(table_prefix\s*=\s*')(wp_')/) {"#{$1}#{@project_name[0,3]}_'"}
            # - write to wp-config
            File.open(File.join(@project_path, "wp-config.php"), "w") {|file| file.puts wp_config}

            # Create project's database
            credentials =   {
                            host: "#{@config_settings['local_host']}",
                            user: "#{@config_settings['local_user']}",
                            pass: "#{@config_settings['local_password']}",
                            name: "#{@project_name}_local_wp",
                            environment: "local"
                            }
            database = Obi::Database.new(@project_name)
            database.create(credentials)
            # enable git repository
            enable_git
            `cd "#{@project_path}" bundle; bower update; guard; sass sprockets`

        end
    end
end



