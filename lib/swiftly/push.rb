require 'swiftly/app_module'
require 'swiftly/Database'

module Swiftly
  class Push < Thor

    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "Push staging environment"

    def staging( project_name )

      settings  = Swiftly::Project.settings( project_name )
      database  = Swiftly::Database.new project_name

      verifiy_mina_credentials  :staging, settings, 'push to the'

      dump_file = database.dump :staging

      database.sync :local, :staging

      mina 'deploy', :staging, project_name

      scp = <<-EOF.unindent
        scp \
        #{dump_file} \
        #{settings[:staging][:userhost]}:#{settings[:staging][:ssh_path]}/current
      EOF

      swiftly_shell scp

    end

    desc "production PROJECT_NAME", "Push production environment"

    def production( project_name )

      settings  = Swiftly::Project.settings( project_name )
      database  = Swiftly::Database.new project_name

      verifiy_mina_credentials  :production, settings, 'push to the'

      dump_file = database.dump :production

      database.sync :local, :production

      mina 'deploy', :production, project_name

      scp = <<-EOF.unindent
        scp \
        #{dump_file} \
        #{settings[:production][:userhost]}:#{settings[:production][:ssh_path]}/current
      EOF

      swiftly_shell scp

    end
  end
end