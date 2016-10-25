require 'yaml'
require 'swiftly/version'
require 'swiftly/app_module'
require 'swiftly/smokestack'
require 'swiftly/resolver'

module Swiftly
  class Config < Thor

    include Helpers

    no_commands do

      def self.global_file

        File.join(
          Dir.home,
          ".#{APP_NAME}"
        ) unless !File.exists? File.join(
          Dir.home,
          ".#{APP_NAME}"
        )

      end

      def self.swiftlyfile

        global_config = self.load :global

        File.join(
          global_config[:sites_path],
          "#{APP_NAME}file".capitalize
        ) unless !File.exists? File.join(
          global_config[:sites_path],
          "#{APP_NAME}file".capitalize
        )

      end

      def self.project_file project_name

        global_config = self.load :global, project_name

        File.join(
          global_config[:sites_path],
          project_name, 'config', 'config.rb'
        ) unless !File.exists? File.join(
          global_config[:sites_path],
          project_name, 'config', 'config.rb'
        )

      end

      def self.wp_config_file project_name

        global_config = self.load :global, project_name

        File.join(
          global_config[:sites_path],
          project_name,
          "wp-config.php"
        ) unless !File.exists? File.join(
          global_config[:sites_path],
          project_name,
          "wp-config.php"
        )

      end

      def self.set setting, *args, &block

        # Ensure that we are only getting the server settings
        return unless setting == :server

        Swiftly::Smokestack.define do

          factory setting, &block

        end

        Swiftly::Resolver.load setting, args[0][:type], Swiftly::Smokestack.build( setting )

      end


      #
      # Loads configuration files for swiftly to use
      # @param file [string] string file path
      # @param project_name = nil [string] name of the project
      #
      # @return [hash] hash of the settings
      def self.load file, project_name = nil

        case file
        when :wp_config

          wp_config_parse project_name


          Resolver.get( :server )

        when :project

          if !eval( IO.read( project_file( project_name ) ) ).nil?

            load_hash = Resolver.get :server == {} ? false : Resolver.get( :server )

          end

        when :swiftly

          if !eval( IO.read( swiftlyfile ) ).nil?

            load_hash = Resolver.get :server

          end

        when :global

          load_hash = YAML.load_file( global_file )

        when :all

          eval( IO.read( swiftlyfile ) ) unless eval( IO.read( swiftlyfile ) ).nil?


          wp_config_parse project_name


          eval( IO.read( project_file( project_name ) ) ) unless eval( IO.read( project_file( project_name ) ) ).nil?



          load_hash = Resolver.get :server

        end


         load_hash

      end

      def self.wp_config_parse project_name

        if wp_config_file( project_name )

          # load the wp-config file environment settings for wp-enabled environments
          wp_local = File.read(
            wp_config_file(
              project_name
            )
          )[/\$local\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

          wp_staging = File.read(
            wp_config_file(
              project_name
            )
          )[/\$staging\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

          wp_production = File.read(
            wp_config_file(
              project_name
            )
          )[/\$production\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

          if wp_local.nil? || wp_staging.nil? || wp_production.nil?

            return {
              local: {},
              staging: {},
              production: {}
            }

          end

          hash = {
            local:       JSON.parse(wp_local).inject({}){|memo,(k,v)| memo[k] = v; memo},
            staging:     JSON.parse(wp_staging).inject({}){|memo,(k,v)| memo[k] = v; memo},
            production:  JSON.parse(wp_production).inject({}){|memo,(k,v)| memo[k] = v; memo}
          }

          hash.each do |k, v|

            set :server, :type => k do

              v.each do |setting, value|

                if setting != 'wp_home'

                  case setting
                    when 'domain'
                      domain value

                    when 'repo'
                      repo value

                    when 'branch'
                      branch value

                    when 'ssh_path'
                      ssh_path value

                    when 'ssh_user'
                      ssh_user value

                    when 'db_name'
                      db_name value

                    when 'db_host'
                      db_host value

                    when 'db_user'
                      db_user value

                    when 'db_pass'
                      db_pass value
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
