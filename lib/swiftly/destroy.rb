require 'swiftly/app_module'
require 'swiftly/database'

module Swiftly
  class Destroy < Thor

    include Thor::Actions
    include Helpers

    desc "destroy PROJECT_NAME", "Destroy local project!"

    def destroy( project_name )

      settings     = Swiftly::Project.settings project_name
      directory    = File.join( settings[:project][:path], '' )
      zipfile_name = settings[:project][:path] + '.zip'

      if File.exist? zipfile_name


        say_status "#{APP_NAME}:", "There is already a zip file named [#{project_name}.zip]. \n\n", :red

        unless yes? set_color "Do you want to overwrite it? [Y/n]", :yellow

          say #spacer
          say_status "#{APP_NAME}:", "No changes were made. Please remove [#{project_name}.zip] before running destroy again.\n\n", :yellow
          abort

        end
      end

      database = Swiftly::Database.new( project_name )

      database.dump( :local )
      database.drop( :local )

      remove_file zipfile_name

      zip zipfile_name, directory

      FileUtils.remove_dir( settings[:project][:path] )

      say #spacer
      say_status "#{APP_NAME}:", "A backup was stored at [#{settings[:project][:path]}.zip].\n\n", :green

    end

    default_task :destroy

  end
end