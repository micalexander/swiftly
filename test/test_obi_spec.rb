require "minitest/autorun"
require_relative "../lib/obi/configuration"

describe ObiConfiguration do

	before do
		@obi = Obi::Configuration
	end

	discribe "when config file created" do
		it "must create config" do
			# @obi.global_config.wont_be :empty?
		end
	end

end


