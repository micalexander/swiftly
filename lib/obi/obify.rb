require "obi/version"

module Obi
	class Obify

		def self.global_config config

			if config
			else
				puts "nothing"
			end

			pattern = /(^(version|local|staging|production)([a-z]*?))(=')(.*?)'\n/

			string = File.read config

			file = string.gsub( pattern ) do |match|
				head = $2
				body = $3
				tail = $5

				if head =~ /version/
					"#{head}#{body}: #{VERSION}\n\n"
				elsif body =~ /project/
					"#{head}_project_directory: #{tail}\n"
				else
					"#{head}_#{body}: #{tail}\n"

				end
			end

			open config, 'w' do |io|
				io.write file
			end
		end

		def self.project_config config

			if config
			else
				puts "nothing"
			end

			pattern = /(^[a-zA-Z\d_]*?)(='|=\(')(.*?)('\)|'|'\s'(.*?)'\))\n/

			string = File.read config

			file = string.gsub( pattern ) do |match|
				head = $1
				body = $3
				tail = $5

				if head =~ /rsync_dirs/
				"#{head}: \n- #{body}\n- #{tail}\n"
				else
				"#{head}: #{body}\n"
				end
			end

			open config, 'w' do |io|
				io.write file
			end

			comments_pattern = /(\#(\s|\S)(.*?)\n\#)/

			comments_string = File.read config

			file = comments_string.gsub( comments_pattern ) do |match|
				head = $1

				"#{head}\n"
			end

			open config, 'w' do |io|
				io.write file
			end
		end
	end
end
