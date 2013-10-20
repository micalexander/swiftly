require 'pathname'
# find_and_replace(input: "file or string", pattern: /regex/, output: "\\1matches\\2", file: booleon )

module Obi
	module FindAndReplace
		def find_and_replace(hash)
			if hash[:file] == true
				replace = File.read(hash[:input]).gsub(hash[:pattern], hash[:output])
				return File.open(hash[:input], "w") {|file| file.puts replace }
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