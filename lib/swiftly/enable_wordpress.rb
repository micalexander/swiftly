require "swiftly/config_templates_generator"
require "swiftly/config_plugins_generator"

module Swiftly
  class Wordpress < Thor

    desc "plugins", "Enable plugins for intergration"
    def plugins()

      ConfigPluginsGenerator.new.create

    end

    desc "templates", "Enable templates for intergrations"

    def templates()

      ConfigTemplateGenerator.new.create

    end
  end
end