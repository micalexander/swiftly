require 'yaml'
require 'swiftly/app_module'
require 'swiftly/configure'

module Swiftly
	class All < Thor

		include Helpers

		desc "all", "Configure all"

		def all()

			say # spacer

			say "\t\t#{APP_NAME} #{VERSION} Development Manager\n\n", :blue

			say_status "#{APP_NAME}:", "Thanks for trying out #{APP_NAME}. Lets get started!", :green

			current = Swiftly::Config.load( :global )

			global_settings = {
				version: VERSION,
				sites_path: current[:sites_path].nil? ? 'not set' : current[:sites_path],
				local: {
					db_host: current[:local][:db_host].nil? ? 'not set' : current[:local][:db_host],
					db_user: current[:local][:db_user].nil? ? 'not set' : current[:local][:db_user],
					db_pass: current[:local][:db_pass].nil? ? 'not set' : current[:local][:db_pass]
					},
				staging: {
					domain:  current[:staging][:domain].nil?  ? 'not set' : current[:staging][:domain],
					db_host: current[:staging][:db_host].nil? ? 'not set' : current[:staging][:db_host],
					db_user: current[:staging][:db_user].nil? ? 'not set' : current[:staging][:db_user],
					db_pass: current[:staging][:db_pass].nil? ? 'not set' : current[:staging][:db_pass]
				},
				production: {
					domain:  current[:production][:domain].nil?  ? 'not set' : current[:production][:domain],
					db_host: current[:production][:db_host].nil? ? 'not set' : current[:production][:db_host],
					db_user: current[:production][:db_user].nil? ? 'not set' : current[:production][:db_user],
					db_pass: current[:production][:db_pass].nil? ? 'not set' : current[:production][:db_pass]
				}
			}

			questions = {
				sites_path:   "\n\n--> What is the absolute path to the folder \n\s\s\s\swhere you keep all of your sites? Currently: (#{global_settings[:sites_path]}):",
				local_db_host: "\n--> What is your local hostname? Currently: (#{global_settings[:local][:db_host]}):",
				local_db_user: "\n--> What is your local mysql username? Currently: (#{global_settings[:local][:db_user]}):",
				local_db_pass: "\n--> What is your local mysql password? Currently: (#{global_settings[:local][:db_pass]}):",
				staging_server_domain: "\n--> What is your staging server domain? Currently: (#{global_settings[:staging][:domain]}):",
				staging_db_host: "\n--> What is your staging server hostname? Currently: (#{global_settings[:staging][:db_host]}):",
				staging_db_user: "\n--> What is your staging server mysql username? Currently: (#{global_settings[:staging][:db_user]}):",
				staging_db_pass: "\n--> What is your staging server mysql password? Currently: (#{global_settings[:staging][:db_pass]}):",
				production_server_domain: "\n--> What is your production server domain? Currently: (#{global_settings[:local][:domain]}):",
				production_db_host: "\n--> What is your production server hostname? Currently: (#{global_settings[:local][:db_host]}):",
				production_db_user: "\n--> What is your production server mysql username? Currently: (#{global_settings[:local][:db_user]}):",
				production_db_pass: "\n--> What is your production server mysql password? Currently: (#{global_settings[:local][:db_pass]}):"
			}

			questions.each do |type, question|

				answer = type === :sites_path ? File.expand_path( ask(question, :yellow, :path => true) ) : ask( question, :yellow, :path => true )

				until yes? "\n--> Got it! Is this correct? #{answer = answer == "" ? question[/\((.*)\)/, 1] : answer} [Y|n]", :green do

					answer = type === :sites_path ? File.expand_path( ask(question, :yellow, :path => true) ) : ask( question, :yellow, :path => true )

				end

				if type === :sites_path

					global_settings[type] = answer

				else

					split       = type.to_s.split('_')
					environment = split.first.to_sym
					setting     = split[1] + '_' + split.last

					global_settings[environment][setting.to_sym] = answer

				end

			end

			say_status "\n\s\s\s\sAll done thanks!", "From now on I will use your new settings."

			File.open(Swiftly::Config.global_file,'w') do |h|

				 h.write global_settings.to_yaml

			end
		end

		default_task :all

	end
end
