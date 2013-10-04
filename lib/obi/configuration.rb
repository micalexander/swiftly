require 'Thor'

module Obi
	class Configuration < Thor
		include Thor::Actions

		attr_accessor :version, :localprojectdirectory, :localsettings, :localhost, :localuser, :localpassword, :stagingsettings, :stagingdomain, :staginghost, :staginguser, :stagingpassword, :productionsettings, :productiondomain, :productionhost, :productionuser, :productionpassword

		def update_config(config_variable, config_value)
			File.open(".obiconfig", 'r+') do |file|
				file.each_line do |line|
					if line =~ /#{config_variable}/
						# find = line.scan(/:.[^#\n]*/)
						# find.each do |f|
						puts
							gsub_file ".obiconfig", /#{Regexp.escape(line)}/ do |match|
							   "#{config_variable}: #{config_value}\n"
							end
						# end
					end
				end
			end
		end

	end
end
