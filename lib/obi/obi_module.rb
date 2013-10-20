
# find_and_replace(input: "file or string", pattern: /regex/, output: "\\1matches\\2", file: booleon )

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

