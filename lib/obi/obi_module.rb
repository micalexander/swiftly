require 'pathname'
# find_and_replace(input: "file or string", pattern: /regex/, output: "\\1matches\\2", file: booleon )

module Obi
	module FindAndReplace
		def find_and_replace(hash)
			if hash[:file] == true
				replace = File.read(hash[:input]).gsub(hash[:pattern], hash[:output])
				File.open(hash[:input], "w") {|file| file.puts replace }
				return hash[:input]
	        else
		 		return hash[:input].gsub(hash[:pattern], hash[:output])
		 	end
		end
	end
end

# get current working directory basename
module Obi
	module GetCurrentDirectoryBasename
		def get_current_directory_basename(project_name)
			case project_name
			when "."
				# print working directory basename
				project_name = Pathname.new(Dir.pwd).basename
			end
			return project_name
		end
	end
end

# see if project exist
module Obi
	module ProjectExist
		def project?(project)
			if !File.directory?( project )
				puts ""
				puts "obi: The project [ #{project} ] doesn't exist"
				puts ""
				exit
			end
		end
	end
end

# fix php serial
module Obi
	module FixSerialization
		def fix_serialization file

			Encoding.default_external = Encoding::UTF_8
			Encoding.default_internal = Encoding::UTF_8
			string = File.read file

			fixed = fix_text string

			open file, 'w' do |io|
			io.write fixed
			end

			return file
		end

		# php escapes:
		# "\\" #Backslash, '"' Double quotes,    "\'" Single quotes, "\a" Bell/alert,
		# "\b" Backspace,  "\r" Carriage Return, "\n" New Line,      "\s" Space,      "\t" Tab

		def fix_text string
			pattern = /(s\s*:\s*)(\d+)((\s*:\\*["&])(.*?)(\\?\"\s*;))/
			php_escapes = /(\\"|\\'|\\\\|\\a|\\b|\\n|\\r|\\s|\\t|\\v)/

			string.gsub( pattern ) do |match|
				head = $1
				tail = $3

				count = $5.bytesize - $5.scan(php_escapes).length

				"#{head}#{count}#{tail}"
			end
		end
	end
end
