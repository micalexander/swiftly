require 'swiftly/app_module'
require 'swiftly/Database'

module Swiftly
  class Setup < Thor

    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "setup staging server"

    def staging( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :staging, settings, 'setup the'

      mina 'setup', :staging, project_name

    end

    desc "production PROJECT_NAME", "setup production server"

    def production( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :production, settings, 'setup the'

      mina 'setup', :production, project_name

    end
  end
end
