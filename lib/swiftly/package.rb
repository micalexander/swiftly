module Swiftly
  class Package

    attr_accessor :name
    attr_accessor :location
    attr_accessor :status

    def self.file

      @settings = Swiftly::Config.load :global

      File.join(
        @settings[:sites_path],
      "#{APP_NAME.capitalize}file",
      ) unless !File.exists?(
        File.join(
          @settings[:sites_path],
          "#{APP_NAME.capitalize}file"
        )
      )

    end

    def self.set package_type, *args, &block

      unless package_type == @package_type &&
             args[0][:type] == @type
        return
      end

      Swiftly::Smokestack.define do

        factory package_type, &block

      end

      self.load args[0][:type], Swiftly::Smokestack.build( package_type )

    end

    #
    # Loads the class variable @package with an hash
    # with package objects by package types
    #
    # @param type [symbol] Type of package either :plugin or :template
    # @param attributes [obj] The package object
    #
    # @return [type] [description]
    def self.load type, attributes

      @packages[type] << attributes
    end


    #
    # Return a package back to the requester
    # @param type [symbol] Type of package either :plugin or :template
    # @param name [string] The name of the package to be returned
    #
    # @return [obj] An object of the package
    def self.retrieve type, name

      # Gather all packages
      self.gather type

      # Check to see if the class variable packages
      # contain packages that match the passed in type
      if !@packages[type].nil?

        # If so the loop over all the packages
        @packages[type].each do |package|

          # Check to see if one thereis one
          # that matches the passed in name
          if package.name == name

            # If so the return it
            return package
          end
        end

      end

      # If all goes bad then return false
      return false
    end

    def self.all type

      self.gather type

      return false if @packages[type].nil? && type == :plugin

      @packages
    end

    def self.gather type

      # Set the type
      @type = type

      # Ready the package hash
      @packages = {
        type => []
      }

      # Set defaults
      self.defaults

      proc = Proc.new {}

      # Evalutes the config file and runs the methods on the file
      eval( IO.read( self.file ), proc.binding, self.file)
    end
  end
end