require 'fileutils'
require 'zip'
require 'swiftly/project'
require 'swiftly/database'
require 'swiftly/app_module'
require 'swiftly/create_project'
require 'swiftly/create_git'
require 'swiftly/create_wordpress'

module Swiftly
  class Create < Thor

    include Helpers

    desc "create project PROJECT_NAME", "Create an empty project"

    def project( project_name )

      project_path = File.join(
        Swiftly::Config.load( :global )[:sites_path],
        project_name
      )

      CreateProject.new([
        project_name,
        project_path
      ]).invoke_all

    end

    desc "create git PROJECT_NAME", "Create an empty (git enabled) project"

    def git( project_name )

      settings = Swiftly::Config.load :global

      project_path = File.join(
        settings[:sites_path],
        project_name
      )

      CreateProject.new( [
        project_name,
        project_path
      ] ).invoke_all

      CreateGit.new([
        project_path
      ]).invoke_all

    end

    desc "create wordpress PROJECT_NAME", "Create a wordpress (git enabled) project"
    method_option :template, aliases: '-t', type: :string, default: :default, desc: 'Provide the name of the template to use'


    def wordpress project_name

      global_settings  = Swiftly::Config.load :global
      project_settings = Swiftly::Config.load :swiftly
      template = Swiftly::Template.retrieve :wordpress, options[:template]

      say_status "#{APP_NAME}:", "Wordpress template #{options[:template]} cannot be found.", :yellow unless template

      abort unless template

      project_path = File.join(
        global_settings[:sites_path],
        project_name
      )

      CreateProject.new([
        project_name,
        project_path
      ]).invoke_all

      CreateWordpress.new([
        project_name,
        template,
        project_path
      ]).invoke_all

      CreateGit.new([
        project_path
      ]).invoke_all

    end
  end
end



