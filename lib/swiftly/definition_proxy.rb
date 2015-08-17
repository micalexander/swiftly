require "swiftly/smokestack"
require "swiftly/factory"

module Swiftly
  class DefinitionProxy

    def factory(factory_class, &block)

      factory = Swiftly::Factory.new

      factory.instance_eval(&block)

      Smokestack.registry[Swiftly.const_get(factory_class.capitalize)] = factory

    end
  end
end