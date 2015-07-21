require 'yaml'
require 'swiftly/app_module'
require 'swiftly/configure'

module Swiftly
	class Local < Thor

		include Helpers

		desc "configure local host", "Configure local hostname"

		def host( value = false )

			update_setting_dialog( :local, :db_host, value )

		end

		desc "configure local username", "Configure local database username"

		def username( value = false )

			update_setting_dialog( :local, :db_user, value )

		end

		desc "configure local password", "Configure local database password"

		def password( value = false )

			update_setting_dialog( :local, :db_pass, value )

		end
	end
end
