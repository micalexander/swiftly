require "swiftly/config"
require "yaml"

module Swiftly
  class Packages < Thor

    include Thor::Actions

    no_commands do

      def self.file

        @settings = Swiftly::Config.load :global

        File.join(
          @settings[:sites_path],
          'Swiftlyfile',
        ) unless !File.exists?(
          File.join(
            @settings[:sites_path],
            'Swiftlyfile'
          )
        )

      end

      def self.check?

        if File.exists? self.file

          true

        else

          false

        end
      end

      def self.available

        YAML.load_file self.file

      end

      def self.template

        {
          name:     'mask',
          location: 'https://github.com/micalexander/mask/archive/master.zip'
        }

      end

      def self.load package = {}

        approved_package = nil

        if self.available &&
          !self.available[package[:framework]].nil? &&
          !self.available[package[:framework]][package[:type]].nil?

          self.available[package[:framework]][package[:type]].each do |p|

            if ( p[:name] == package[:name] && p[:status] != :disabled ) ||
               ( p[:status] == :default )

              approved_package = p

            else

              approved_package = self.template

            end
          end

        elsif !self.available

          approved_package = self.template

        end

        if !approved_package.nil? &&
           (
            approved_package[:location] =~ /^#{URI::regexp}\.zip$/ ||
            File.exist?( File.join( approved_package[:location], approved_package[:name] ) )
           )

          return approved_package

        end

        false

      end

      def self.load_plugins framework

        plugins = []

        if self.available &&
          !self.available[framework].nil? &&
          !self.available[framework][:plugins].nil?

          self.available[framework][:plugins].each do |p|

            verified = self.load({
              framework: framework,
              type:      :plugins,
              name:      p[:name]
            })

            if verified

              plugins << verified

            end
          end

          if plugins.count > 0

            return plugins

          end

          false

        end
      end
    end
  end
end