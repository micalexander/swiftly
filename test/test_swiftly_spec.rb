require "minitest/autorun"
require_relative "../lib/swiftly/configuration"

module Swiftly
  describe Swiftly::ConfigGlobal do

    before do
      @swiftly = Swiftly::ConfigGlobal
    end

    describe "when config file created" do
      it "must create config" do
        @swiftly.create
      end
    end
  end
end

