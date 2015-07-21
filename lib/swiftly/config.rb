require 'yaml'
require 'swiftly/version'
require 'swiftly/app_module'

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

      def self.project_file project_name

        global_config = self.load :global, project_name

        File.join(
          global_config[:sites_path],
          project_name, 'config', 'config.yml'
        ) unless !File.exists? File.join(
          global_config[:sites_path],
          project_name, 'config', 'config.yml'
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

      def self.load file, project_name = nil

        case file
        when :wp_config

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

            load_hash = {
              local:       JSON.parse(wp_local).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
              staging:     JSON.parse(wp_staging).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo},
              production:  JSON.parse(wp_production).inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
            }

          end

        when :project

          load_hash = YAML.load_file( project_file( project_name ) )

        when :global

          load_hash = YAML.load_file( global_file )

        end

         load_hash

      end
    end
  end
end
