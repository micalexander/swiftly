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

		desc "create project PROJECT_NAME", "Create a create project"

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

		desc "create git PROJECT_NAME", "Create a create git enabled project"

		def git( project_name )

			settings = Swiftly::Config.load( :global )

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

		desc "create git PROJECT_NAME", "Create a create wordpress (git enabled) project"
		method_option :template, aliases: '-t', type: :string, default: :default, desc: 'Provide the name of the template to use'


		def wordpress( project_name )

			settings = Swiftly::Config.load( :global )

			if ( options[:template] == :default )

				template = Swiftly::AddOn.load_default_template framework: :wordpress, type: :template

			else

				template = Swiftly::AddOn.load framework: :wordpress, type: :template, name: options[:template]

			end

			project_path = File.join(
				settings[:sites_path],
				project_name
			)

			CreateProject.new([
				project_name,
				project_path
			]).invoke_all

			CreateWordpress.new([
				project_name,
				template,
				settings,
				project_path
			]).invoke_all

			CreateGit.new([
				project_path
			]).invoke_all

		end
	end
end



