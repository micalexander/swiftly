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

      current = Swiftly::Config.load :global

      global_settings = {
        version: VERSION,
        sites_path: current[:sites_path].nil? ? 'not set' : current[:sites_path],
      }

     swiftly_settings = {
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
        sites_path:               "\n\n--> What is the absolute path to the folder \n\s\s\s\swhere you keep all of your sites? Currently: (\e[0;m#{global_settings[:sites_path]}\e[33;m):",
        local_db_host:            "\n--> What is your local hostname? Currently: (\e[0;m#{swiftly_settings[:local][:db_host]}\e[33;m):",
        local_db_user:            "\n--> What is your local mysql username? Currently: (\e[0;m#{swiftly_settings[:local][:db_user]}\e[33;m):",
        local_db_pass:            "\n--> What is your local mysql password?",
        staging_server_domain:    "\n--> What is your staging server domain? Currently: (\e[0;m#{swiftly_settings[:staging][:domain]}\e[33;m):",
        staging_db_host:          "\n--> What is your staging server hostname? Currently: (\e[0;m#{swiftly_settings[:staging][:db_host]}\e[33;m):",
        staging_db_user:          "\n--> What is your staging server mysql username? Currently: (\e[0;m#{swiftly_settings[:staging][:db_user]}\e[33;m):",
        staging_db_pass:          "\n--> What is your staging server mysql password?",
        production_server_domain: "\n--> What is your production server domain? Currently: (\e[0;m#{swiftly_settings[:production][:domain]}\e[33;m):",
        production_db_host:       "\n--> What is your production server hostname? Currently: (\e[0;m#{swiftly_settings[:production][:db_host]}\e[33;m):",
        production_db_user:       "\n--> What is your production server mysql username? Currently: (\e[0;m#{swiftly_settings[:production][:db_user]}\e[33;m):",
        production_db_pass:       "\n--> What is your production server mysql password?"
      }

      responses = ['y','Y','']

      questions.each do |type, question|

        confirm = false

        until confirm == true do

          if type === :sites_path

            answer = File.expand_path( ask question, :yellow, :path => true )

          elsif type === :local_db_pass      ||
                type === :staging_db_pass    ||
                type === :production_db_pass

            answer = ask question, :yellow, :echo => false

          else

            answer = ask question, :yellow

          end

          if type === :sites_path && answer == ''

            answer = global_settings[:sites_path]

          elsif type === :local_db_pass      ||
                type === :staging_db_pass    ||
                type === :production_db_pass

            password = ask "\n\n--> Please re-enter your password?", :yellow, :echo => false

            say #spacer

            until password == answer

              say_status "#{APP_NAME}:", "Passwords did not match please try again.\n", :yellow

              answer = ask question, :yellow, :echo => false

              password = ask "\n--> Please re-enter your password?\n", :yellow, :echo => false

            end

            if password == answer

              if answer == ''

                answer = nil

              end

              confirm = true

            end

          elsif answer == ''

            if question[/\e\[[0-9;]*[a-zA-Z](.*)\e\[[0-9;]*[a-zA-Z]/, 1] == ''

              answer = nil

            else

              answer = question[/\e\[[0-9;]*[a-zA-Z](.*)\e\[[0-9;]*[a-zA-Z]/, 1]

            end
          end

          unless type === :local_db_pass      ||
                 type === :staging_db_pass    ||
                 type === :production_db_pass

            if responses.include? ask( "\n--> Got it! Is this correct? \e[32;m#{answer}\e[0;m [Y|n]")

                confirm = true

            end
          end

        end

        if type === :sites_path

          global_settings[type] = answer

        else

          split       = type.to_s.split('_')
          environment = split.first.to_sym
          setting     = split[1] + '_' + split.last

          if type === :staging_server_domain ||
             type === :production_server_domain

            setting     = split.last

          end

          swiftly_settings[environment][setting.to_sym] = answer

        end

      end

      say_status "\n\s\s\s\sAll done thanks!", "From now on I will use your new settings."

      File.open(Swiftly::Config.global_file,'w') do |h|

         h.write swiftly_settings.to_yaml

      end
    end

    default_task :all

  end
end
