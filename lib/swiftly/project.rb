require 'Thor'
require 'yaml'
require 'swiftly/app_module'

module Swiftly
  class Project < Thor

    include Thor::Actions
    include Helpers

    no_commands do

      def self.set setting, *args, &block

        Swiftly::Smokestack.define do

          factory setting, &block

        end

        Swiftly::Resolver.load setting, args[0][:type], Swiftly::Smokestack.build( setting )

      end

      def self.settings project_name = nil

        project_name    = self.get_project project_name
        global_config   = Swiftly::Config.load :global
        swiftlyfile     = Swiftly::Config.swiftlyfile
        project_file    = Swiftly::Config.project_file project_name
        wp_config       = Swiftly::Config.wp_config_file project_name

        eval( IO.read( swiftlyfile ) ) unless eval( IO.read( swiftlyfile ) ).nil?

        wp_config_parse wp_config

        eval( IO.read( project_file ) ) unless eval( IO.read( project_file ) ).nil?

        settings = Resolver.get :server

        settings[:global] = global_config

        settings[:project] = {
          name: project_name,
          path: File.join( global_config[:sites_path], project_name ),
          dump: File.join( global_config[:sites_path], project_name, '_backups', 'dumps' )
        }

        if defined?( settings[:staging][:ssh_user] ) &&
           defined?( settings[:staging][:domain] ) &&
           settings[:staging][:ssh_user] != nil  &&
           settings[:staging][:domain] != nil

          settings[:staging][:userhost] = settings[:staging][:ssh_user] + '@' + settings[:staging][:domain].gsub(/http:\/\//, "")

        end

        if defined?( settings[:production][:ssh_user] ) &&
           defined?( settings[:production][:domain] ) &&
           settings[:production][:ssh_user] != nil  &&
           settings[:production][:domain] != nil

          settings[:production][:userhost] = settings[:production][:ssh_user] + '@' + settings[:production][:domain].gsub(/http:\/\//, "")

        end

        settings

      end

      def self.wp_config_parse file

        if file

          # load the wp-config file environment settings for wp-enabled environments
          wp_local = File.read( file )[/\$local\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

          wp_staging = File.read( file )[/\$staging\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

          wp_production = File.read( file )[/\$production\s*?=[\s|\S]*?({[\s|\S]*?})/, 1]

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

      def self.get_project( project_name )

        pathname     = Pathname.new project_name
        settings     = Swiftly::Config.load( :global )
        project_path = File.join( settings[:sites_path], pathname.expand_path.basename )

        thor = Thor.new

        thor.say #spacer

        thor.say_status( "#{APP_NAME}:", "#{project_path} is not a project.\n", :yellow ) &&
        abort unless File.directory?( project_path )

        pathname.expand_path.basename.to_s

      end

      def self.exists?( project_name )

        settings     = Swiftly::Config.load( :global )
        project_path = File.join( settings[:sites_path], project_name )

        File.directory?( project_path )

      end
    end
  end
end