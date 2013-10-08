require 'net/http'

require 'fileutils'
require 'git'
require 'zip'

module Obi
    class Project

        @@config_settings = Obi::Configuration.settings

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
            @@project_name = project_name
            @@project_path = File.join( @@config_settings['local_project_directory'], @@project_name )
        end

        def create_directories
            if !File.directory?(@@project_path)
                asset_path_str = "parent_folder/sub_dir/{ai,architecture,content,emails,estimates,fonts,gif,jpg,pdf,png,psd}"
                dumps_path_str = "parent_folder/sub_dir/{local,production,staging,temp}"
                asset_paths = asset_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@@project_path}/_resources/assets/" << s }
                dumps_paths = dumps_path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{@@project_path}/_resources/dumps/" << s }
                FileUtils.mkdir_p [asset_paths, dumps_paths], {:noop => false, :verbose => false}
                FileUtils.mkdir File.join(@@project_path, ".obi"), {:noop => false, :verbose => false}
                File.open(File.join( @@project_path, ".obi", "config"), "w") do |file|
                    file.puts "#\n# Production ssh settings\n#\n\nenable_production_ssh: 0\nproduction_ssh: 0\nproduction_remote_project_root: 0\nenable_production_sshmysql: 0\n\n#\n# Staging ssh settings\n#\n\nenable_staging_ssh: 0\nstaging_ssh: 0\nstaging_remote_project_root: 0\nenable_staging_sshmysql: 0\n\n#\n# S3 settings\n#\n\nenable_S3: 0\npublic_key: 0\nsecret_key: 0\nmybucket: 0\n\n#\n# RSync settings\n#\n\nenable_rsync: 0\nrsync_dirs:\n - /change/this/to/first/sync/directory/\n - /change/this/to/second/sync/directory/or/remove/entirely/"
                end
                File.open(File.join( @@project_path, ".obiignore"), "w") { |file| file.puts ".git\n.gitignore\n.htaccess\nsftp-config.json\n.DS_Store\n_resources\n.obi" }
            else
                puts ""
                puts "obi: There is already a project with that name. Please try again."
                puts ""
                return false
            end
        end

        def enable_git
            File.open(File.join( @@project_path, ".gitignore"), "w") { |file| file.puts "_resources/\n.obi\n.obiignore" }
            git = Git.init( @@project_path )
            git.add
            git.commit_all('initial commit')
        end



        def wordpress
            returned_value = create_directories

            if returned_value != false

                # download wordpress and place it in the project directory
                wordpress = RedirectFollower.new('http://wordpress.org/latest.zip').resolve
                File.open(File.join( @@project_path, "latest.zip"), "w") do |file|
                    file.write wordpress.body
                end

                # unzip the wordpress zip file
                zipfile_name = File.join(@@project_path, 'latest.zip')
                Zip::File.open(zipfile_name) do |zipfile|
                    # entry is an instance of Zip::ZipEntry
                    zipfile.each do |entry|
                        entry_file_path = File.join(@@project_path , entry.to_s)
                        # FileUtils.mkdir_p(File.dirname(entry_file_path))
                        zipfile.extract(entry, entry_file_path)
                    end
                end

                # remove wordpress folder and zip file
                FileUtils.rm(File.join(@@project_path, 'latest.zip'))
                FileUtils.mv( Dir[File.join(@@project_path, 'wordpress/*')], @@project_path )
                FileUtils.rmdir(File.join(@@project_path, 'wordpress'))

                # download the mask framwork
                # get_mask
                mask = RedirectFollower.new('https://github.com/micalexander/mask/archive/master.zip').resolve
                File.open(File.join( @@project_path, "wp-content", "themes", "master.zip"), "w") do |file|
                    file.write mask.body
                end

                # unzip the mask zip file
                zipfile_name = File.join(@@project_path, "wp-content", "themes","master.zip")
                Zip::File.open(zipfile_name) do |zipfile|
                    # entry is an instance of Zip::ZipEntry
                    zipfile.each do |entry|
                        entry_file_path = File.join(@@project_path, "wp-content", "themes", entry.to_s)
                        # FileUtils.mkdir_p(File.dirname(entry_file_path))
                        zipfile.extract(entry, entry_file_path)
                    end
                end

                # remove mask folder and zip file
                FileUtils.rm(File.join(@@project_path, "wp-content", "themes", "master.zip"))
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "mask-master"), File.join(@@project_path, "wp-content", "themes", "#{@@project_name}"))

                # Move the wp-config, .htaccess, Guardfile, Gemfile, and Gemfile.lock files to the site root
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", ".htaccess"), @@project_path )
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "wp-config.php"), @@project_path )
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "Guardfile"), @@project_path )
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "Gemfile"), @@project_path )
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "Gemfile.lock"), @@project_path )

                # Move site specific plugin to the plugins folder
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "mask-specific-plugin"), File.join(@@project_path, "wp-content", "plugins", "#{@@project_name}-specific-plugin"))
                FileUtils.mv(File.join(@@project_path, "wp-content", "plugins", "#{@@project_name}-specific-plugin",  "mask-plugin.php"), File.join(@@project_path, "wp-content", "plugins", "#{@@project_name}-specific-plugin", "#{@@project_name}-plugin.php"))

                # # Find and replace the mask name with the project name
                FileUtils.mv(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "img", "wp-login-logo-mask.png"), File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "img", "wp-login-logo-#{@@project_name}.png"))

                # # Find and replace the mask name with the project name
                plugin_file = File.read(File.join(@@project_path, "wp-content", "plugins", "#{@@project_name}-specific-plugin", "#{@@project_name}-plugin.php"))
                function_file = File.read(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "functions.php"))
                guard_file = File.read(File.join(@@project_path, "Guardfile"))
                ie_file = File.read(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "sass", "ie.scss"))
                plugin_replace = plugin_file.gsub(/mask/, "#{@@project_name}".capitalize)
                function_replace = function_file.gsub(/mask/, "#{@@project_name}")
                guard_replace = guard_file.gsub(/mask/, "#{@@project_name}")
                ie_replace = ie_file.gsub(/mask/, "#{@@project_name}")
                File.open(File.join(@@project_path, "wp-content", "plugins", "#{@@project_name}-specific-plugin", "#{@@project_name}-plugin.php"), "w") {|file| file.puts plugin_replace}
                File.open(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "functions.php"), "w") {|file| file.puts function_replace}
                File.open(File.join(@@project_path, "Guardfile"), "w") {|file| file.puts guard_replace}
                File.open(File.join(@@project_path, "wp-content", "themes", "#{@@project_name}", "sass", "ie.scss"), "w") {|file| file.puts ie_replace}

                # enable git repository
                enable_git
            end
        end
    end
end



