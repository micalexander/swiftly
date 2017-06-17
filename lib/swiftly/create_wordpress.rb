require "thor/group"
require 'rubygems'
require 'active_support'
require 'swiftly/app_module'
require 'active_support/core_ext/string'
require 'git'

module Swiftly
  class CreateWordpress < Thor::Group

    include Thor::Actions
    include Helpers

    argument :project_name
    argument :template
    argument :project_path

    desc "Handles the creation of a wordpress project."

    #
    # Define the source root of this file
    #
    # @return [string] The path to this file
    def self.source_root

      File.dirname(__FILE__)

    end


    #
    # This method grabs the latest version of wordpress,
    # unzips it and places it into the project directory
    #
    # @return [void]
    def get_wordpress

      # change directory into the project path
      inside @project_path do

        # download Wordpress unless it already exists
        get 'https://wordpress.org/latest.zip', 'latest.zip' unless File.exist? 'wordpress'

        # unzip the zip unless it is already unzipped
        unzip 'latest.zip', 'wordpress' unless File.exist? 'wordpress'

        # remove the zip file if the zip file exists
        remove_file 'latest.zip' unless !File.exist? 'latest.zip'

        # Grab all of the folders out of the wordpress directory
        Dir[File.join('wordpress', '*')].each do |e|

          # Move all of the folders our of the wordpress directory
          # and into the root of the project if it exists
          FileUtils.mv( e, @project_path ) unless File.exist? e.gsub(/^wordpress/, @project_path )

        end

        # Remove the empty wordpress directory if it still exits
        remove_file 'wordpress' unless !(Dir.entries('wordpress') - %w{ . .. }).empty?
      end
    end


    #
    # Download or get theme for a location on the hard drive
    # and add it to the Wordpress theme folder
    #
    # @return [void]
    def get_theme

      # Check to see if the template name is default and if it
      # is then change it to the default template name
      @template.name = Swiftly::Template.default_name if @template.name == :default

      # Change directories to inside of the theme directory
      inside File.join( @project_path, 'wp-content', 'themes') do

        # Check to see if the theme is a zip file
        if @template.location =~ /^#{URI::regexp}\.zip$/

          # If the theme is a zip file then download the theme
          zipfile = get @template.location, File.basename( @template.location )

          # Unzip the theme if it has not been unzipped already
          unzip zipfile, @template.name unless File.exist? @template.name.to_s

          # Rmove the zipfile if it still exists
          remove_file zipfile unless !File.exist? zipfile

        else

          # If the theme location does not point to a zip file
          # then the theme to the theme folder
          FileUtils.cp_r( File.join( @template.location, @template.name.to_s ), '.' )

        end

        # Change the theme name from whatever it was named
        # into the the name of the project
        FileUtils.mv( @template.name.to_s, @project_name ) unless !File.exists? @template.name.to_s

        # Change directories
        inside @project_name do

          # Loop through each of these files
          # and delete them if the exist
          [
            '.git',
            '_resources',
            '.gitignore',
            '.htaccess',
            ".#{APP_NAME}",
            ".#{APP_NAME}ignore"
          ].each do |file|

            remove_file file unless !File.exists? file

          end

          # Loop through each of these files
          # and perform a find and replace to change
          # the theme name into the name of the project
          [
            '.htaccess',
            'wp-config.php',
            'bower.json',
            'config.rb',
            'Guardfile',
            'Gemfile',
            'Gemfile.lock'
          ].each do |file|

            gsub_file file, /(#{@template.name})/, @project_name.gsub(/\-|\./, '_') unless !File.exists? file

            FileUtils.mv( file, @project_path ) unless !File.exists? file

          end

          # Move the project specific plugin into the
          # plugins directory if it exists
          FileUtils.mv(
            "#{@template.name}-specific-plugin",
            File.join( @project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin")
          ) unless !File.exists? "#{@template.name}-specific-plugin"

          # Change the name of the theme logo
          # if it exists
          FileUtils.mv(
            File.join( "wp-login-logo-#{@template.name}.png" ) ,
            File.join( "wp-login-logo-#{@project_name}.png" )
          ) unless !File.exists? File.join( "wp-login-logo-#{@template.name}.png" )

          # Perform a find and replace on the function file to
          # change any mentions of the theme name into the name of the project
          gsub_file 'functions.php', /(#{@template.name})/, @project_name

        end

      end

      # Change directories into the project specific plugin
      inside File.join( @project_path, "wp-content", "plugins", "#{@project_name}-specific-plugin") do

        # Change the file name to match the project name
        FileUtils.mv(
          "#{@template.name}-plugin.php",
          "#{@project_name}-plugin.php"
        ) unless !File.exists? "#{@template.name}-plugin.php"

        # Perform a find and replace files to match the project name
        gsub_file "#{@project_name}-plugin.php", /(#{@template.name})/, @project_name.capitalize unless !File.exists? "#{@template.name}-plugin.php"

      end
    end

    #
    # Download or get plugins for a location on the hard drive
    # and add it to the Wordpress plugins folder
    #
    # @return [void]
    def get_plugins

      # Change directories into the plugins directory
      inside File.join( @project_path, "wp-content", "plugins" ) do

        # Get all the Wordpress plugins from specified in
        # the config and in the Swiftlyfolder
        plugins = Swiftly::Plugin.all :wordpress

        # Check to see if any plugins are available
        if plugins

          # If plugins are available then
          # loop through all the plugins
          plugins[:wordpress].each do |plugin|

            # If a plugin is zipped up
            if plugin.location =~ /^#{URI::regexp}\.zip$/

              # Set the plugin up to be unzipped
              zipfile = get plugin.location, File.basename( plugin.location )

              # Unzip the plugin if it exists
              unzip zipfile, plugin.name unless File.exist? plugin.name.to_s

              # Remove the zip file if it exists
              remove_file zipfile unless !File.exist? zipfile

            else

              # If the plugin is not zipped then just
              # copy it to the plugin folder
              FileUtils.cp_r( File.join( plugin.location, plugin.name.to_s ), '.' ) unless File.exist? plugin.name.to_s

            end
          end
        end
      end
    end

    #
    # Handle the wp-config file in peperations for database set up
    #
    # @return [void]
    def wp_config

      # Change directories into the project directory
      inside File.join @project_path do

        # Get rid of the sample wp-config file
        remove_file "wp-config-sample.php"

        # Add salts to the wp-config file
        gsub_file 'wp-config.php', /\/\/\s*Insert_Salts_Below/, Net::HTTP.get('api.wordpress.org', '/secret-key/1.1/salt')

        # Change the table prefix for the database
        gsub_file 'wp-config.php', /(table_prefix\s*=\s*')(wp_')/, '\1' + @project_name[0,3] + "_'"

        # Retrieve the server settings for the
        # local database
        settings = Swiftly::Config.load :swiftly

        # Check to see if all of the database settings
        # are present
        if !settings.nil? &&
           !settings[:local][:db_host].nil? &&
           !settings[:local][:db_user].nil? &&
           !settings[:local][:db_pass].nil?

          # If the database settings are present the
          # perform a find and replace on the local wp-config
          # database settings
          gsub_file 'wp-config.php', /(\$local\s*?=[\s|\S]*?)({[\s|\S]*?})/  do |match|

            '$local = \'{
          "db_name": "' + @project_name.gsub(/\-|\./, '_') + '_local_wp",
          "db_host": "' + settings[:local][:db_host] + '",
          "db_user": "' + settings[:local][:db_user] + '",
          "db_pass": "' + settings[:local][:db_pass] + '",
          "domain":  "http://' + @project_name + '.dev",
          "wp_home": "http://' + @project_name + '.dev"
        }'

          end
        end

      end
    end


    #
    # Create the database for the project
    #
    # @return [void]
    def create_database

      # Create a new database object
      database = Swiftly::Database.new @project_name

      # Create a new database
      database.create :local

    end


    #
    # Take care of any of the project dependencies
    #
    # @return [void]
    def dependencies

      # Change directories into the project directory
      inside File.join @project_path do

        # Run all the possible installs if any of the
        # package managers exists
        run('bundle')            unless !File.exists? 'Gemfile'
        run('bundle exec guard') unless !File.exists? 'Guardfile'
        run('npm install')       unless !File.exists? 'package.json'
        run('bower update')      unless !File.exists? 'bower.json'
      end
    end
  end
end
