require "obi/version"
require "thor/group"

module Obi
	class GlobalConfig < Thor::Group

		include Thor::Actions

		desc "Handles the creation of the config file."

		def self.source_root
			File.dirname(__FILE__)
		end

		def create
			@version = VERSION
			template "templates/global_config.erb", Configuration.global_file
		end
	end
end