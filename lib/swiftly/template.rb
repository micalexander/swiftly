require "swiftly/package"

module Swiftly
  class Template < Package

    @package_type  = :template

    #
    # Sets the default template name to be used when
    # running find and replace on the the template files
    #
    # @return [symbol] The name of the template
    def self.default_name

      :mask
    end

    def self.defaults

      self.set :template, :type => :wordpress do

        name     :default
        location 'https://github.com/micalexander/mask/archive/master.zip'
        status   :enabled

      end
    end
  end
end
