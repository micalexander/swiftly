require "date"
require "obi/Configuration"

module Obi
	class Menu

		attr_accessor :config_settings

		# possible menu actions/choices
		@@choices = ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','quit']

		# get actions
		def self.actions
			@@choices
		end

		# get settings
		def initialize
			@config_settings = Obi::Configuration.settings
		end


		# launch the interactive config menu
		def launch!(message=nil)
			unless message
				message = "Your project working directory is currently set to: #{@config_settings['local_project_directory']}"
			end
			@msg = message
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
			until @@choices.include?(action)
				puts "\nAvailable choices: " + @@choices.join(", ") if action
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
				@msg = "#{instruction}" unless setting_variable =~ /(local_settings|staging_settings|production_settings)/
				self.menu_output
				configuration = Obi::Configuration.new
				if setting_variable =~ /(local_settings|staging_settings|production_settings)/
					configuration.update_config_setting(setting_variable)
				else
					print "> "
					user_response = $stdin.gets.chomp.rstrip.gsub(/\\/, "" )
					if setting_variable =~ /local_project_directory/
						puts setting_variable
						if !File.directory?(user_response)
							confirmation = "Your input was was not a directory so there has been no change:"
						else
							configuration.update_config_setting(setting_variable, user_response)
						end
					elsif user_response.nil? or user_response == 0 or user_response.empty?
						confirmation = "Your input was empty therefore there has been no change:"
					else
						configuration.update_config_setting(setting_variable, user_response)
					end
				end
				Obi::Configuration.settings = Obi::Configuration.global_file
				@config_settings = Obi::Configuration.settings

				launch!("#{confirmation} #{@config_settings[setting_variable]}")
			end

			# based on users chosen action carry out the action
			case action
			when '1'
				carry_out_action "Please enter your desired project working directory into this window without the trailing slash and press ENTER", 'local_project_directory', "Your project working directory is currently set to:"
			when '2'
				carry_out_action 'local_settings', "Your local server settings has been set to:"
			when '3'
				carry_out_action 'Please enter your local database host', 'local_host', "Your local database host has been changed to:"
			when '4'
				carry_out_action 'Please enter your local database user', 'local_user', "Your local database user has been changed to:"
			when '5'
				carry_out_action 'please enter you local database password', 'local_password', "Your local database password has been changed to:"
			when '6'
				carry_out_action 'staging_settings', "Your staging server settings has been set to:"
			when '7'
				carry_out_action 'Please enter your staging domain', 'staging_domain', "Your staging domain has been changed to:"
			when '8'
				carry_out_action 'Please enter your staging database host', 'staging_host', "Your staging database host has been changed to:"
			when '9'
				carry_out_action 'Please enter your staging database user', 'staging_user', "Your staging database user has been changed to:"
			when '10'
				carry_out_action 'Please enter your staging database password', 'staging_password', "Your staging database password has been changed to:"
			when '11'
				carry_out_action 'production_settings', "Your production server settings has been set to:"
			when '12'
				carry_out_action 'please enter you production domain', 'production_domain', "Your production domain has been changed to:"
			when '13'
				carry_out_action 'Please enter your production database host', 'production_host', "Your production database host has been changed to:"
			when '14'
				carry_out_action 'Please enter your production database user', 'production_user', "Your production database user has been changed to:"
			when '15'
				carry_out_action 'Please enter your production database password', 'production_password', "Your production database password has been changed to:"
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

			1. Change project working directory. \033[33m#{@config_settings['local_project_directory']}\033[0m

			2. Toggle local server settings. \033[33m#{@config_settings['local_settings']}\033[0m
			3. Change local database host currently set to \033[33m#{@config_settings['local_host']}\033[0m
			4. Change local database user currently set to \033[33m#{@config_settings['local_user']}\033[0m
			5. Change local database password currently set to \033[33m#{@config_settings['local_password']}\033[0m

			\033[4;37mStaging Enviornment \033[0m

			6. Toggle staging server settings. \033[33m#{@config_settings['staging_settings']}\033[0m
			7. Change staging database domain currently set to \033[33m#{@config_settings['staging_domain']}\033[0m
			8. Change staging host currently set to \033[33m#{@config_settings['staging_host']}\033[0m
			9. Change staging database user currently set to \033[33m#{@config_settings['staging_user']}\033[0m
			10. Change staging database password currently set to \033[33m#{@config_settings['staging_password']}\033[0m

			\033[4;37mProduction Enviornment \033[0m

			11. Toggle production server settings. \033[33m#{@config_settings['production_settings']}\033[0m
			12. Change production database domain currently set to \033[33m#{@config_settings['production_domain']}\033[0m
			13. Change production database host currently set to \033[33m#{@config_settings['production_host']}\033[0m
			14. Change production database user currently set to \033[33m#{@config_settings['production_user']}\033[0m
			15. Change production database password currently set to \033[33m#{@config_settings['production_password']}\033[0m

			quit. Exit and return back to the terminal


			obi: \033[36m#{@msg}\033[0m

			Select by pressing the number and then ENTER
			eos
		end

	end
end
