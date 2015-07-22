require 'thor'
require 'json'
require 'swiftly/config_global_generator'
require 'swiftly/config_swiftlyfile_generator'
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

        responses = ['y','Y','']

        questions = {
          sites_path: "\n\n--> What is the absolute path to the folder \n\s\s\s\swhere you keep all of your sites? (\e[0;m#{Dir.home}\e[33;m):",
          db_host:    "\n--> What is your local hostname? (\e[0;mlocalhost\e[33;m):",
          db_user:    "\n--> What is your local mysql username? (\e[0;mroot\e[33;m):",
          db_pass:    "\n--> What is your local mysql password?"
        }

        questions.each do |type, question|

          confirm = false

          until confirm == true do

            if type === :sites_path

              answer = File.expand_path( ask question, :yellow, :path => true )

            elsif type === :db_pass

              answer = ask question, :yellow, :echo => false

            else

              answer = ask question, :yellow

            end

            if type === :sites_path && answer == ''

              answer = Dir.home

            elsif type === :db_pass

              password = ask "\n\n--> Please re-enter your password?", :yellow, :echo => false

              say #spacer

              until password == answer

                say_status "#{APP_NAME}:", "Passwords did not match please try again.\n", :yellow

                answer = ask question, :yellow, :echo => false

                password = ask "\n--> Please re-enter your password?\n", :yellow, :echo => false

              end

              if password == answer

                confirm = true

              end

            elsif answer == ''

              if question[/\e\[[0-9;]*[a-zA-Z](.*)\e\[[0-9;]*[a-zA-Z]/, 1] == ''

                answer = nil

              else

                answer = question[/\e\[[0-9;]*[a-zA-Z](.*)\e\[[0-9;]*[a-zA-Z]/, 1]

              end
            end

            unless type === :db_pass



              if responses.include? ask( "\n--> Got it! Is this correct? \e[32;m#{answer}\e[0;m [Y|n]")

                  confirm = true

              end
            end
          end

            settings << answer

        end

        say_status "\n\s\s\s\sThats it!", "You can now run [#{APP_NAME} help] for more options."

      end

      Swiftly::ConfigGlobalGenerator.new([
        settings[0]
      ]).invoke_all

      ConfigSwiftlyfileGenerator.new([
        settings[1],
        settings[2],
        settings[3]
      ]).invoke_all

    end

    default_task :init

  end
end
