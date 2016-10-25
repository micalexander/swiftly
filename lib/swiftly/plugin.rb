require "swiftly/package"

module Swiftly
  class Plugin < Package

    attr_accessor :muplugin

    @package_type  = :plugin

    def self.defaults

      global = Swiftly::Config.load :global

      if File.directory? File.join(global[:sites_path], "#{APP_NAME}folder".capitalize)

        app_folder = File.join(global[:sites_path], "#{APP_NAME}folder".capitalize)

        if File.directory? File.join app_folder, 'plugins'

          plugin_folder = File.join app_folder, 'plugins'

          plugins = Dir.glob(File.join(plugin_folder, '*')).select {|f| File.directory? f}

          plugins.each do |location|

            self.set :plugin, :type => :wordpress do

              name     File.basename location
              location File.join app_folder, 'plugins'
              status   :enabled

            end
          end
        end
      end
    end
  end
end