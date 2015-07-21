require 'swiftly/app_module'

module Swiftly
  class Clean < Thor

    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "Clean production environment"

    def staging( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :staging, settings, 'clean the'

      mina 'deploy:cleanup', :staging, project_name

    end

    desc "production PROJECT_NAME", "Clean production environment"

    def production( project_name )

      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :production, settings, 'clean the'

      mina 'deploy:cleanup', :production, project_name

    end
  end
end