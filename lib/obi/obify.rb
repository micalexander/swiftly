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
				else
					"#{head}_#{body}: #{tail}\n"

				end
			end

			open config, 'w' do |io|
				io.write file
			end
		end
	end
end

