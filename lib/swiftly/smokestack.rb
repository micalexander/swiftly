require 'swiftly/definition_proxy'

module Swiftly
  module Smokestack

    @registry = {}

    def self.registry

      @registry

    end

    def self.define(&block)

      definition_proxy = Swiftly::DefinitionProxy.new
      definition_proxy.instance_eval(&block)

    end

    def self.build(factory_class, overrides = {})

      instance   = Swiftly.const_get(factory_class.capitalize).new
      factory    = registry[Swiftly.const_get(factory_class.capitalize)]
      attributes = factory.attributes.merge(overrides)

      attributes.each do |attribute_name, value|

        instance.send("#{attribute_name}=", value)

      end

      instance

    end
  end
end