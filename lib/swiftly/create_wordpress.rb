require "thor/group"
require 'rubygems'
require 'active_support'
require 'swiftly/add_on'
require 'swiftly/app_module'
require 'active_support/core_ext/string'
require 'git'

module Swiftly
  class CreateWordpress < Thor::Group

    include Thor::Actions
    include Helpers

    argument :project_name
    argument :template
    argument :settings
    argument :project_path

    desc "Handles the creation of a wordpress project."

    def self.source_root

      File.dirname(__FILE__)

    end

    def get_wordpress()

      # download wordpress and place it in the project directory
      inside @project_path do

        get 'https://wordpress.org/latest.zip', 'latest.zip' unless File.exist? 'wordpress'

        unzip 'latest.zip', 'wordpress' unless File.exist? 'wordpress'

        remove_file 'latest.zip' unless !File.exist? 'latest.zip'

        Dir['wordpress/*'].each do |e|

          FileUtils.mv( e, @project_path ) unless File.exist? e.gsub(/^wordpress/, @project_path )

        end

        remove_file 'wordpress' unless !(Dir.entries('wordpress') - %w{ . .. }).empty?

        inside File.join( 'wp-content', 'themes') do

          if @template[:remote] =~ /^#{URI::regexp}$/

            zipfile = get @template[:remote], File.basename( @template[:remote] )

            unzip zipfile, @template[:name] unless File.exist? @template[:name]

            remove_file zipfile unless !File.exist? zipfile

          else

            FileUtils.cp_r( File.join( @settings[:sites_path], "#{APP_NAME}folder", 'templates', @template[:name] ), '.' )

          end

          FileUtils.mv( @template[:name], @project_name ) unless !File.exists? @template[:name].capitalize

          inside @project_name do

            [
              '.git',
              '_resources',
              '.gitignore',
              '.htaccess',
              ".#{APP_NAME}",
              ".#{APP_NAME}ignore"
            ].each do |e|

              remove_file e

            end

            [
              '.htaccess',
              'wp-config.php',
              'bower.json',
              'config.rb',
              'Guardfile',
              'Gemfile',
              'Gemfile.lock'
            ].each do |file|

              gsub_file file, /(#{@template[:name]})/, @project_name unless !File.exists? file

              FileUtils.mv( file, @project_path ) unless !File.exists? file

            end

            FileUtils.mv(
              "#{@template[:name]}-specific-plugin",
              File.join( @project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin")
            ) unless !File.exists? "#{@template[:name]}-specific-plugin"

            FileUtils.mv(
              File.join( "wp-login-logo-#{@template[:name]}.png" ) ,
              File.join( "wp-login-logo-#{@project_name}.png" )
            ) unless !File.exists? File.join( "wp-login-logo-#{@template[:name]}.png" )

            gsub_file 'functions.php', /(#{@template[:name]})/, @project_name

          end
        end

        inside File.join( "wp-content", "plugins", "#{@project_name}-specific-plugin") do

          FileUtils.mv(
            "#{@template[:name]}-plugin.php",
            "#{@project_name}-plugin.php"
          ) unless !File.exists? "#{@template[:name]}-plugin.php"

          gsub_file "#{@project_name}-plugin.php", /(#{@template[:name]})/, @project_name.capitalize unless !File.exists? "#{@template[:name]}-plugin.php"

        end

        inside File.join( "wp-content", "plugins" ) do

          plugins = Swiftly::AddOn.load framework: :wordpress, type: :plugins

          if plugins.count > 0

            # grab global plugins if they exist
            plugins.each do |directory, plugin|

              plugin_dir = File.join( @settings[:sites_path], "#{APP_NAME}folder",'plugins', directory)

              FileUtils.cp_r( plugin_dir, '.' ) unless File.exist? File.join( ".", directory )

            end
          end
        end

        # add plugins to the functions file
        # Plugins.add_plugins_to_functions_file @project_path

        remove_file "wp-config-sample.php"

        gsub_file 'wp-config.php', /\/\/\s*Insert_Salts_Below/, Net::HTTP.get('api.wordpress.org', '/secret-key/1.1/salt')
        gsub_file 'wp-config.php', /(table_prefix\s*=\s*')(wp_')/, '\1' + @project_name[0,3] + "_'"
        gsub_file 'wp-config.php', /(\$local\s*?=[\s|\S]*?)({[\s|\S]*?})/  do |match|

          '$local = \'{
        "db_name": "' + @project_name + '_local_wp",
        "db_host": "' + @settings[:local][:db_host] + '",
        "db_user": "' + @settings[:local][:db_user] + '",
        "db_pass": "' + @settings[:local][:db_pass] + '",
        "domain":  "http://' + @project_name + '.dev",
        "wp_home": "http://' + @project_name + '.dev"
      }'

        end

        database = Swiftly::Database.new( @project_name )

        database.create( :local )

        run('bundle')            unless !File.exists? 'Gemfile'
        run('bundle exec guard') unless !File.exists? 'Guardfile'
        run('bower update')      unless !File.exists? 'bower.json'

      end
    end
  end
end