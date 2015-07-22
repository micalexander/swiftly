require 'Thor'
require 'yaml'
require 'swiftly/app_module'

module Swiftly
  class Project < Thor

    include Thor::Actions
    include Helpers

    no_commands do

      def self.settings( project_name )

        project_name   = self.get_project project_name
        global_config  = Swiftly::Config.load :global
        swiftly_config = Swiftly::Config.load :swiftly
        project_config = Swiftly::Config.load :project,   project_name
        wp_config      = Swiftly::Config.load :wp_config, project_name

        global_config  = {
          version:    VERSION,
          sites_path: global_config[:sites_path],
        }

        switly_config  = {
          staging: {
            domain:  defined?(project_config[:staging][:domain])  ? project_config[:staging][:domain]  : global_config[:staging][:domain],
            db_host: defined?(project_config[:staging][:db_host]) ? project_config[:staging][:db_host] : global_config[:staging][:db_host],
            db_user: defined?(project_config[:staging][:db_user]) ? project_config[:staging][:db_user] : global_config[:staging][:db_user],
            db_pass: defined?(project_config[:staging][:db_pass]) ? project_config[:staging][:db_pass] : global_config[:staging][:db_pass],
          },
          production: {
            domain:  defined?(project_config[:production][:domain])  ? project_config[:production][:domain]  : global_config[:production][:domain],
            db_host: defined?(project_config[:production][:db_host]) ? project_config[:production][:db_host] : global_config[:production][:db_host],
            db_user: defined?(project_config[:production][:db_user]) ? project_config[:production][:db_user] : global_config[:production][:db_user],
            db_pass: defined?(project_config[:production][:db_pass]) ? project_config[:production][:db_pass] : global_config[:production][:db_pass],
          }
        }.merge! local: global_config[:local]

        settings = {
          project: {
            name: project_name,
            path: File.join( global_config[:sites_path], project_name ),
            dump: File.join( global_config[:sites_path], project_name, '_backups', 'dumps' )
          },
          local: {
            domain:  defined?(wp_config[:local][:domain])  ? wp_config[:local][:domain]  : project_config[:local][:domain],
            db_name: defined?(wp_config[:local][:db_name]) ? wp_config[:local][:db_name] : project_config[:local][:db_name],
            db_host: defined?(wp_config[:local][:db_host]) ? wp_config[:local][:db_host] : switly_config[:local][:db_host],
            db_user: defined?(wp_config[:local][:db_user]) ? wp_config[:local][:db_user] : switly_config[:local][:db_user],
            db_pass: defined?(wp_config[:local][:db_pass]) ? wp_config[:local][:db_pass] : switly_config[:local][:db_pass],
          },
          staging: {
            db_name:  defined?(wp_config[:staging][:db_name])    ? wp_config[:staging][:db_name] : project_config[:staging][:db_name],
            db_host:  defined?(wp_config[:staging][:db_host])    ? wp_config[:staging][:db_host] : switly_config[:staging][:db_host],
            db_user:  defined?(wp_config[:staging][:db_user])    ? wp_config[:staging][:db_user] : switly_config[:staging][:db_user],
            db_pass:  defined?(wp_config[:staging][:db_pass])    ? wp_config[:staging][:db_pass] : switly_config[:staging][:db_pass],
            domain:   defined?(switly_config[:staging][:domain]) ? switly_config[:staging][:domain]  : wp_config[:staging][:domain],
            repo:     project_config[:staging][:repo],
            branch:   project_config[:staging][:branch],
            ssh_path: project_config[:staging][:ssh_path],
            ssh_user: project_config[:staging][:ssh_user],
          },
          production: {
            db_name:  defined?(wp_config[:production][:db_name])    ? wp_config[:production][:db_name] : project_config[:production][:db_name],
            db_host:  defined?(wp_config[:production][:db_host])    ? wp_config[:production][:db_host] : switly_config[:production][:db_host],
            db_user:  defined?(wp_config[:production][:db_user])    ? wp_config[:production][:db_user] : switly_config[:production][:db_user],
            db_pass:  defined?(wp_config[:production][:db_pass])    ? wp_config[:production][:db_pass] : switly_config[:production][:db_pass],
            domain:   defined?(switly_config[:production][:domain]) ? switly_config[:production][:domain]  : wp_config[:production][:domain],
            repo:     project_config[:production][:repo],
            branch:   project_config[:production][:branch],
            ssh_path: project_config[:production][:ssh_path],
            ssh_user: project_config[:production][:ssh_user],
          }
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

      def self.get_project( project_name )

        pathname     = Pathname.new project_name
        settings     = Swiftly::Config.load( :global )
        project_path = File.join( settings[:sites_path], pathname.expand_path.basename )

        thor = Thor.new

        thor.say #spacer

        thor.say_status( "#{APP_NAME}:", "#{project_path} is not a project.\n", :yellow ) &&
        abort unless File.directory?( project_path )

        pathname.expand_path.basename

      end

      def self.exists?( project_name )

        settings     = Swiftly::Config.load( :global )
        project_path = File.join( settings[:sites_path], project_name )

        File.directory?( project_path )

      end
    end
  end
end