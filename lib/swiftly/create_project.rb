require "thor/group"
require 'rubygems'
require 'active_support'
require 'swiftly/project'
require 'swiftly/app_module'
require 'swiftly/config_project_generator'
require 'active_support/core_ext/string'

module Swiftly
	class CreateProject < Thor::Group

		include Thor::Actions
		include Helpers

		argument :project_name
		argument :project_path

		desc "Handles the creation of project files."

		def self.source_root

			File.dirname(__FILE__)

		end

		def no_commands

			def allow_project_creation

				if Swiftly::Project.exists?(@project_name)

					say #spacer
					say_status "#{APP_NAME}:", "There is already a project named #{@project_path}", :red
					abort

				end
			end
		end

		def create_assets()

			allow_project_creation

			['architecture', 'doc', 'emails', 'fonts', 'images', 'raster', 'vector'].each do |path|

				empty_directory( File.join( @project_path ,"_resources", "assets", path ) )

			end
		end

		def create_dump_directories

			['local','production','staging','temp'].each do |path|

				empty_directory( File.join( @project_path , "_backups", "dumps", path ) )

			end

		end

		def create_project_config

			ConfigProjectGenerator.new.create(@project_path)

		end
	end
end