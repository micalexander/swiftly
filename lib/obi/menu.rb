require "date"
require "obi/Configuration"

module Obi
	class Menu

		# possible menu actions/choices
		@@actions = ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','quit']
		@@config_settings = Obi::Configuration.settings
		@@msg = "Your project working directory is currently set to: #{@@config_settings['local_project_directory']}"

		# get actions
		def self.actions
			@@actions
		end

		# launch the interactive config menu
		def launch_menu!(message=@@msg)
			@@msg = message
			menu_output
			result = nil
			until result == :quit
				action, args = get_action
				result = do_action(action, args)
			end
		end

		# get users action choice
		def get_action
			action = nil
			# Keep asking for user input until we get a valid action
			until @@actions.include?(action)
				puts "\nActions: " + @@actions.join(", ") if action
				print "> "
				user_response = $stdin.gets.chomp
				args = user_response.downcase.strip.split(' ')
				action = args.shift
			end
			return action, args
		end

		# carry out action based on users choice
		def do_action(action, args=[])

			def carry_out_action(instruction=nil, setting_variable, confirmation)
				@@msg = "#{instruction}" unless setting_variable =~ /(local_settings|staging_settings|production_settings)/
				self.menu_output
				configuration = Obi::Configuration.new
				if setting_variable =~ /(local_settings|staging_settings|production_settings)/
					configuration.update_config_setting(setting_variable)
				else
					print "> "
					user_response = gets.chomp.rstrip.gsub(/\\/, "" )
					unless user_response.nil? or user_response == 0 or user_response.empty? or !File.directory?(user_response)
						configuration.update_config_setting(setting_variable, user_response)
					else
						confirmation = "Your input was empty therefore there has been no change"
					end
				end
				Obi::Configuration.settings=CONFIG_FILE_LOCATION
				@@config_settings = Obi::Configuration.settings

				self.launch_menu!("#{confirmation} #{@@config_settings[setting_variable]}")
			end

			# based on users chosen action carry out the action
			case action
			when '1'
				carry_out_action "Please enter your desired project working directory without the trailing slash or \n\t\t\t\t     simply drag and drop the desired folder into this window and press ENTER", 'local_project_directory', "Your project working directory is currently set to:"
			when '2'
				carry_out_action 'local_settings', "Your project working directory is currently set to:"
			when '3'
				carry_out_action 'please enter you local project directory path', 'local_host', "Your local host has been changed to: "
			when '4'
				carry_out_action 'please enter you local project directory path', 'local_user'
			when '5'
				carry_out_action 'please enter you local project directory path', 'local_password'
			when '6'
				carry_out_action 'staging_settings', "Your project working directory is currently set to:"
			when '7'
				carry_out_action 'please enter you local project directory path', 'staging_domain'
			when '8'
				carry_out_action 'please enter you local project directory path', 'staging_host'
			when '9'
				carry_out_action 'please enter you local project directory path', 'staging_user'
			when '10'
				carry_out_action 'please enter you local project directory path', 'staging_password'
			when '11'
				carry_out_action 'production_settings'
			when '12'
				carry_out_action 'please enter you local project directory path', 'production_domain'
			when '13'
				carry_out_action 'please enter you local project directory path', 'production_host'
			when '14'
				carry_out_action 'please enter you local project directory path', 'production_user'
			when '15'
				carry_out_action 'please enter you local project directory path', 'production_password'
			when 'quit'
				return :quit
			else
				puts "\nI don't understand that command.\n"
			end
		end

		# display menu
		def menu_output
			system ("clear")
			print <<-eos
			Obi

			\033[36mYet another Jedi mindtrick\033[0m

			\033[4;37mLocal Enviornment \033[0m

			1. Toggle local server settings. \033[33m#{@@config_settings['local_project_directory']}\033[0m

			2. Toggle local server settings. \033[33m#{@@config_settings['local_settings']}\033[0m
			3. Change local database host currently set to \033[33m#{@@config_settings['local_host']}\033[0m
			4. Change local database user currently set to \033[33m#{@@config_settings['local_user']}\033[0m
			5. Change local database password currently set to \033[33m#{@@config_settings['local_password']}\033[0m

			\033[4;37mStaging Enviornment \033[0m

			6. Toggle staging server settings. \033[33m#{@@config_settings['staging_settings']}\033[0m
			7. Change staging database domain currently set to \033[33m#{@@config_settings['staging_domain']}\033[0m
			8. Change staging host currently set to \033[33m#{@@config_settings['staging_host']}\033[0m
			9. Change staging database user currently set to \033[33m#{@@config_settings['staging_user']}\033[0m
			10. Change staging database password currently set to \033[33m#{@@config_settings['staging_password']}\033[0m

			\033[4;37mProduction Enviornment \033[0m

			11. Toggle production server settings. \033[33m#{@@config_settings['production_settings']}\033[0m
			12. Change production database domain currently set to \033[33m#{@@config_settings['production_domain']}\033[0m
			13. Change production database host currently set to \033[33m#{@@config_settings['production_host']}\033[0m
			14. Change production database user currently set to \033[33m#{@@config_settings['production_user']}\033[0m
			15. Change production database password currently set to \033[33m#{@@config_settings['production_password']}\033[0m

			quit. Exit and return back to the terminal


			obi: \033[36m#{@@msg}\033[0m

			Select by pressing the number and then ENTER
			eos
		end

	end
end
