require "date"

module Obi

	class Menu

		class Config
			@@actions = ['1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','quit']
			def self.actions; @@actions; end
		end

		def launch_menu!
			menu_output
			result = nil
			until result == :quit
				action, args = get_action
				result = do_action(action, args)
			end
		end

		def get_action
			action = nil
			# Keep asking for user input until we get a valid action
			until Menu::Config.actions.include?(action)
				puts "\nActions: " + Menu::Config.actions.join(", ") if action
				print "> "
				user_response = gets.chomp
				args = user_response.downcase.strip.split(' ')
				action = args.shift
			end
			return action, args
		end

		def do_action(action, args=[])
			case action
			when 'list'
				list(args)
			when 'find'
				keyword = args.shift
				find(keyword)
			when 'add'
				add
			when 'quit'
				return :quit
			else
				puts "\nI don't understand that command.\n"
			end
		end

		def menu_output
			system ("cls")
			puts "\t\t      `date`"
			puts
			puts "\t\t\t\t $logo"
			puts
			puts "\t\033[36m A Jedi's Workflow designed for the 21rst century"
			puts "\033[0m"
			puts "\t" "\033[4;37mLocal Enviornment \033[0m"
			puts
			puts "\t""$aprompt"
			puts
			puts "\t""$bprompt"
			puts "\t""$cprompt"
			puts "\t""$dprompt"
			puts "\t""$eprompt"
			puts
			puts "\t" "\033[4;37mStaging Enviornment \033[0m"
			puts
			puts "\t""$fprompt"
			puts "\t""$gprompt"
			puts "\t""$hprompt"
			puts "\t""$iprompt"
			puts "\t""$jprompt"
			puts
			puts "\t" "\033[4;37mProduction Enviornment \033[0m"
			puts
			puts "\t""$kprompt"
			puts "\t""$lprompt"
			puts "\t""$mprompt"
			puts "\t""$nprompt"
			puts "\t""$oprompt"
			puts
			puts "\tx. Exit and return back to the terminal"
			puts
			puts
			puts "obi: $MSG"
			puts "\033[0m"
			puts "Select by pressing the number and then ENTER" ;
		end

	end
end
