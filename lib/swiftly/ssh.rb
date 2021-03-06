require 'swiftly/app_module'
require 'swiftly/database'

module Swiftly
  class SSH < Thor

    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "SSH into staging server and cd into site root"

    def staging( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :staging, settings, 'ssh into the'

      mina 'ssh', :staging, project_name

    end

    desc "production PROJECT_NAME", "SSH into production server and cd into site root"

    def production( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :production, settings, 'ssh into the'

      mina 'ssh', :production, project_name

    end

  end
end

