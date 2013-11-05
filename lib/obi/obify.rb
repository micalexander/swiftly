require "obi/version"

module Obi
	class Obify

		def self.global_config config

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

			pattern = /((^[a-zA-Z\d_]*?)(='|=\()(('.*?|.*?)('\n|'\))))|((\#(\s|\S)(.*?)\n\#))/

			string = File.read config

			file = string.gsub( pattern ) do |match|
				head = $2
				body = $4
				tail = $5
				foot = $7

				direc = ""
				if head =~ /rsync_dirs/
					body.split(' ').each do |b|
						direc << "\n- #{b[/'(.*?)'/,1]}"
					end
					"#{head}: #{direc}"
				elsif foot =~ /#/
					"#{foot}\n"
				else
					"#{head}: #{tail}\n"
				end
			end

			open config, 'w' do |io|
				io.write file
			end
		end
	end
end
