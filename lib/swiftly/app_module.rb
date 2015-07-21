require 'Thor'
require 'pathname'
require 'awesome_print'

class String

  # Unindent heredocs so they look better
  def unindent

    gsub(/^[\t|\s]*|[\t]*/, "")

  end
end

module Swiftly
  module Helpers

    thor = Thor.new

    def zip zipfile_name, directory

      Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|

        Dir[ File.join(directory, '**', '**') ].each do |file|

          zipfile.add(file.sub( directory, '' ), file )

        end
      end
    end

    def unzip zipfile_name, directory

      Zip::File.open( zipfile_name ) do |zipfile|

        zipfile.each do |entry|

          path = entry.name.to_s.gsub(/^.+?#{File::SEPARATOR}/, "#{directory}#{File::SEPARATOR}")

          say_status "unzip", zipfile.extract( entry, path.to_s ) unless File.exist?(path)

        end
      end
    end

    def find_and_replace(hash)

      if hash[:file] == true

        if File.exists? hash[:input]

          replace = File.read(hash[:input]).gsub(hash[:pattern], hash[:output])

          File.open(hash[:input], "w") {|file| file.puts replace }

          return hash[:input]

        else

            say_status "#{APP_NAME}:", "file #{hash[:input]} does not exist", :yellow

        end

      else

        return hash[:input].gsub(hash[:pattern], hash[:output])

      end
    end

    def find_and_replace_all(array)

      array.each do |hash|

        find_and_replace(hash)

      end
    end

    def return_cmd cmd

      cmd_return = ""

      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|

        exit_status = wait_thr.value

        while line  = stdout_err.gets

          cmd_return = line

        end

        say #spacer

        unless exit_status.success?

          # TURN ON FOR SIMPLE DEBUGGING
          # abort "\n\s\s\s\s#{APP_NAME}: command failed - #{cmd}\n\n"

        end
      end

      cmd_return

    end

    def swiftly_shell(cmd, command_status = nil)

      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|

        exit_status = wait_thr.value

        while line  = stdout_err.gets

          say_status cmd.split( ' ' ).first.gsub(/^mina/, APP_NAME), line.gsub(/^mina/, APP_NAME).gsub(/----->/, "    \033[34m\e[1m#{command_status}\e[0m\033[0m")

        end

        say #spacer

        unless exit_status.success?

          # TURN ON FOR SIMPLE DEBUGGING
          # abort "\n\s\s\s\s#{APP_NAME}: command failed - #{cmd}\n\n"

        end
      end
    end

    def verifiy_mina_credentials environment, settings, verbage

        if settings[environment][:repo].nil?

          say_status "#{APP_NAME}:", "Could not #{verbage} to #{environment} environment, because the repository is not set.", :red
          say #spacer

        end

        if settings[environment][:branch].nil?

          say_status "#{APP_NAME}:", "Could not #{verbage} to #{environment} environment, because the branch is not set.", :red
          say #spacer

        end

        if settings[environment][:ssh_user].nil?

          say_status "#{APP_NAME}:", "Could not #{verbage} to #{environment} environment, because the ssh user is not set.", :red
          say #spacer

        end

        if settings[environment][:ssh_path].nil?

          say_status "#{APP_NAME}:", "Could not #{verbage} to #{environment} environment, because the ssh path is not set.", :red
          say #spacer

        end

        if settings[environment][:domain].nil?

          say_status "#{APP_NAME}:", "Could not #{verbage} to #{environment} environment, because the domain is not set.", :red
          say #spacer

        end

        abort if settings[environment][:repo].nil?
        abort if settings[environment][:branch].nil?
        abort if settings[environment][:ssh_user].nil?
        abort if settings[environment][:domain].nil?
        abort if settings[environment][:ssh_path].nil?

    end

    def mina cmd, environment, project_name

      settings = Swiftly::Project.settings( project_name )

      inside settings[:project][:path] do

        cmd_status = cmd.include?(':') ? cmd.split(':').last : cmd

        mina = <<-EOF.unindent
          mina #{cmd} \
          -f '#{File.join(File.dirname(__FILE__), "Rakefile")}' \
          repo='#{settings[environment][:repo]}' \
          branch='#{settings[environment][:branch]}' \
          user='#{settings[environment][:ssh_user]}' \
          domain='#{settings[environment][:domain].gsub(/http:\/\//, '')}' \
          path='#{settings[environment][:ssh_path]}'
        EOF

        if cmd == 'ssh'

          exec mina

        else

          swiftly_shell mina, cmd_status

        end
      end
    end

    def update_setting environment, setting, value

      config                       = Swiftly::Config.load( :global )
      config[environment][setting] = value

      File.open(Swiftly::Config.global_file,'w') do |h|

         h.write config.to_yaml

      end
    end

    def update_setting_dialog( environment, setting, value )

      nouns = {
        domain:  'domain',
        db_host: 'host',
        db_user: 'username',
        db_pass: 'password'
      }

      say # spacer

      current_setting = Swiftly::Config.load( :global )[environment][setting]
      current_value   = current_setting.nil? ? 'nothing' : current_setting

      say_status "#{APP_NAME}:", "The staging #{nouns[setting]} is currently set to #{current_value}.", :yellow

      say # spacer

      if value

        if yes? "Are you sure you want to set it to (#{value})? [Y|n]", :yellow

          update_setting environment, setting, value

          new_setting = Swiftly::Config.load( :global )[environment][setting]

          say # spacer

          say_status "#{APP_NAME}:", "Change successful! The value is set to #{new_setting}"

        end

      else

        value = ask "\n--> What would you like to set it to?", :yellow

        say # spacer

        if value == ""

          say_status "#{APP_NAME}:", "Change unsuccessful, #{nouns[setting]} is still set to #{current_value}", :yellow

        else

          update_setting environment, setting, value

          new_setting = Swiftly::Config.load( :global )[environment][setting]

          say # spacer

          say_status "#{APP_NAME}:", "Change successful! #{nouns[setting]} is now set to #{new_setting}"

        end
      end
    end

    def fix_serialization file

      Encoding.default_external = Encoding::UTF_8
      Encoding.default_internal = Encoding::UTF_8
      string                    = File.read file
      fixed                     = fix_text string

      open file, 'w' do |io|

        io.write fixed

      end

      return file

    end

    # php escapes:
    # "\\" #Backslash, '"' Double quotes,    "\'" Single quotes, "\a" Bell/alert,
    # "\b" Backspace,  "\r" Carriage Return, "\n" New Line,      "\s" Space,      "\t" Tab

    def fix_text string

      pattern     = /(s\s*:\s*)(\d+)((\s*:\\*["&])(.*?)(\\?\"\s*;))/
      php_escapes = /(\\"|\\'|\\\\|\\a|\\b|\\n|\\r|\\s|\\t|\\v)/

      string.gsub( pattern ) do |match|

        head  = $1
        tail  = $3
        count = $5.bytesize - $5.scan(php_escapes).length

        "#{head}#{count}#{tail}"
      end
    end
  end
end

