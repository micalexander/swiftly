require "swiftly/package"

module Swiftly
  class Template < Package

    @package_type  = :template

    def self.defaults

      self.set :template, :type => :wordpress do

        name     :default
        location 'https://github.com/micalexander/mask/archive/master.zip'
        status   :enabled

      end
    end
  end
end