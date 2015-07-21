require 'yaml'
require 'swiftly/app_module'
require 'swiftly/configure'

module Swiftly
  class Production < Thor

    include Helpers

    desc "configure production domain", "Configure production domain"

    def domain( value = false )

      update_setting_dialog( :production, :domain, value )

    end

    desc "configure production host", "Configure production hostname"

    def host( value = false )

      update_setting_dialog( :production, :db_host, value )

    end

    desc "configure production username", "Configure production database username"

    def username( value = false )

      update_setting_dialog( :production, :db_user, value )

    end

    desc "configure production password", "Configure production database password"

    def password( value = false )

      update_setting_dialog( :production, :db_pass, value )

    end
  end
end
