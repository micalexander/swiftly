require 'swiftly/generate_post_type'
require 'swiftly/app_module'

module Swiftly
	class Generate < Thor

		include Helpers

		desc "cpt [option] PROJECT_NAME", "Creates Custom Post Type file"

		def cpt(post_type_name, post_type_filter, project_name)

			settings = Swiftly::Project.settings( project_name )

			GeneratePostType.new([
				post_type_name,
				post_type_filter,
				settings[:project]
			]).invoke_all

		end
	end
end