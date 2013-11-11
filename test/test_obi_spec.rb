require "minitest/autorun"
require_relative "../lib/obi/configuration"

module Obi
	describe Obi::Configuration do

		before do
			@obi = Obi::Configuration
		end

		describe "when config file created" do
			it "must create config" do
				@obi.create
			end
		end
	end
end

