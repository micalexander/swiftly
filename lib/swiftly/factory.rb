require "swiftly/server"

module Swiftly
  class Factory < BasicObject

    def initialize

      @attributes = {}

    end

    attr_reader :attributes

    def method_missing(name, *args, &block)

      @attributes[name] = args[0]

    end
  end
end