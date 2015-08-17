require "swiftly/config"
require "swiftly/app_module"
require "yaml"
require "swiftly/factory"

module Swiftly
  class Package < Thor

    include Thor::Actions
    include Helpers

    no_commands do

      attr_accessor :framework
      attr_accessor :type
      attr_accessor :name
      attr_accessor :location

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

        eval( IO.read( self.file ) )

        load_hash = Resolver.get( :package ) == {} ? false : Resolver.get( :package )

      end

      def self.set setting, *args, &block

        Swiftly::Smokestack.define do

          factory setting, &block

        end

        Swiftly::Resolver.load setting, args[0][:type], Swiftly::Smokestack.build( setting )

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
          !self.available[:packages].nil? &&
          !self.available[:packages][package[:framework]].nil? &&
          !self.available[:packages][package[:framework]][package[:type]].nil?

          self.available[:packages][package[:framework]][package[:type]].each do |p|

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
          !self.available[:packages].nil? &&
          !self.available[:packages][framework].nil? &&
          !self.available[:packages][framework][:plugins].nil?

          self.available[:packages][framework][:plugins].each do |p|

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