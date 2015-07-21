require 'swiftly/app_module'
require 'swiftly/Database'

module Swiftly
  class Rollback < Thor
    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "Rollback staging environment"

    def staging( project_name )

      database = Swiftly::Database.new( project_name )
      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :staging, settings, 'rollback to the'

      ssh = <<-EOF.unindent
        ssh \
        -q \
        #{settings[:staging][:userhost]} \
        ls \
        #{settings[:staging][:ssh_path]}/current \
        | grep staging.sql
      EOF

      previous_sql = return_cmd( ssh ).gsub(/[^a-zA-Z0-9\-\.]/,"")

      scp = <<-EOF.unindent
        scp \
        #{settings[:staging][:userhost]}:#{settings[:staging][:ssh_path]}/current/#{previous_sql } \
        #{settings[:project][:dump]}/temp
      EOF

      swiftly_shell scp

      database.import( :staging, "#{settings[:project][:dump]}/temp/#{previous_sql}" )

      mina 'rollback', :staging, project_name

    end

    desc "production PROJECT_NAME", "Rollback production environment"

    def production( project_name )

      database = Swiftly::Database.new( project_name )
      settings = Swiftly::Project.settings( project_name )

      verifiy_mina_credentials :production, settings, 'rollback to the'

      ssh = <<-EOF.unindent
        ssh \
        -q \
        #{settings[:production][:userhost]} \
        ls \
        #{settings[:production][:ssh_path]}/current \
        | grep production.sql
      EOF

      previous_sql = return_cmd( ssh ).gsub(/[^a-zA-Z0-9\-\.]/,"")

      scp = <<-EOF.unindent
        scp \
        #{settings[:production][:userhost]}:#{settings[:production][:ssh_path]}/current/#{previous_sql } \
        #{settings[:project][:dump]}/temp
      EOF

      swiftly_shell scp

      database.import( :production, "#{settings[:project][:dump]}/temp/#{previous_sql}" )

      mina 'rollback', :production, project_name


    end
  end
end