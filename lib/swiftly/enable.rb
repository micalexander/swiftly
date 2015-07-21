require 'swiftly/app_module'
require 'swiftly/enable_wordpress'

module Swiftly
  class Enable < Thor
    include Thor::Actions
    include Helpers

    desc "wordpress [COMMAND]", "Enable wordpress intergrations"
    subcommand "wordpress", Wordpress

  end
end
