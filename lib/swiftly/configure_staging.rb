require 'yaml'
require 'swiftly/app_module'

module Swiftly
	class Staging < Thor

		include Helpers

		desc "configure staging domain", "Configure staging domain"

		def domain( value = false )

			update_setting_dialog( :staging, :domain, value)

		end

		desc "configure staging host", "Configure staging hostname"

		def host( hostname = false )

			update_setting_dialog( :staging, :db_host, value)

		end

		desc "configure staging username", "Configure staging database username"

		def username( username = false )

			update_setting_dialog( :staging, :db_user, value)

		end

		desc "configure staging password", "Configure staging database password"

		def password( password = false )

			update_setting_dialog( :staging, :db_pass, value)

		end
	end
end
