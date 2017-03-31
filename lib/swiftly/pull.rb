require 'swiftly/app_module'
require 'swiftly/database'

module Swiftly
  class Pull < Thor
    include Thor::Actions
    include Helpers

    desc "staging PROJECT_NAME", "Pull down staging environment"

    def staging( project_name )

      Swiftly::Database.new( project_name ).sync( :staging, :local )

    end

    desc "production PROJECT_NAME", "Pull down production environment"

    def production( project_name )

      Swiftly::Database.new( project_name ).sync( :production, :local )

    end
  end
end