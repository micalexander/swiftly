require "swiftly/config"
require "yaml"

module Swiftly
  class AddOn < Thor

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

      def self.load_default_template package = {}

        template = nil

        self.available[package[:framework]][:template].each do |t|

          template = t unless t[:status] != :default

        end

        if ( !template.nil? || template[:remote] =~ /^#{URI::regexp}$/ || File.exist?( File.join( @settings[:sites_path], 'Swiftlyfolder', template[:name] ) ) )

            return template
        end

        {
          name:   'mask',
          remote: 'https://github.com/micalexander/mask/archive/master.zip'
        }

      end

      def self.load package = {}

        if package[:type] == :template

          self.template package

        elsif package[:type] == :plugins

          self.plugins package

        end
      end

      def self.template package

        thor = Thor.new

        template = nil

        self.available[package[:framework]][package[:type]].each do |t|

          template = t unless t[:name] != package[:name] || t[:status] == :disabled

        end

        if !template.nil? &&
           template[:remote] =~ /^#{URI::regexp}$/ ||
           !template.nil? &&
           File.exist?( File.join( @settings[:sites_path], 'Swiftlyfolder', 'templates', template[:name] ) )

          return template

        end

        thor.say # spacer
        thor.say_status "#{APP_NAME}", "No enabled template was found with that name", :yellow
        abort

      end

      def self.plugins package


        plugins = {}

        self.available[package[:framework]][package[:type]].each do |p|

          if File.exist? File.join( @settings[:sites_path], 'Swiftlyfolder', 'plugins' , p )

            plugins[p.split(File::SEPARATOR).first] = p

          end

        end

        plugins

      end
    end
  end
end