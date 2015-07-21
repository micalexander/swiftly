require 'thor'
require 'json'
require 'swiftly/config_global_generator'
require 'swiftly/app_module'

module Swiftly
	class Init < Thor

		include Thor::Actions
		include Helpers

		desc "init", "Initiate  #{APP_NAME.capitalize} for the first time"

		def init

			say # spacer

			say "\t\t#{APP_NAME} #{VERSION} Development Manager\n\n", :blue

			say_status "#{APP_NAME}:", "Thanks for trying out #{APP_NAME}. Lets get started!", :green

			settings = []

			inside Dir.home do

				questions = {
					sites:   "\n\n--> What is the absolute path to the folder \n\s\s\s\swhere you keep all of your sites? (#{Dir.home}):",
					db_host: "\n--> What is your local hostname? (localhost):",
					db_user: "\n--> What is your local mysql username? (root):",
					db_pass: "\n--> What is your local mysql password? (root):"
				}

				questions.each do |type, question|

					answer = type === :sites ? File.expand_path( ask(question, :yellow, :path => true) ) : ask( question, :yellow, :path => true )

					until yes? "\n--> Got it! Is this correct? #{answer = answer == "" ? question[/\((.*)\)/, 1] : answer} [Y|n]", :green do

						answer = type === :sites ? File.expand_path( ask(question, :yellow, :path => true) ) : ask( question, :yellow, :path => true )

					end

					settings << answer

				end

				say_status "\n\s\s\s\sThats it!", "You can now run `#{APP_NAME} help` for more options."

			end

			Swiftly::ConfigGlobalGenerator.new(
				settings
			).invoke_all

			ConfigSwiftlyfileGenerator.new.invoke_all

		end

		default_task :init

	end
end
