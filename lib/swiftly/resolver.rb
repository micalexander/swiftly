module Swiftly
  class Resolver

    @@settings = {
      server: [],
      package: []
    }

    def self.load setting, type, attributes

      @@settings[setting] <<  { type => attributes }

    end

    def self.get setting

      override  = {}
      final     = {}

      if !@@settings[setting].nil?

        @@settings[setting].each do |s|

          s.each do |k, v|

            override[k] = []

          end
        end

        @@settings[setting].each do |s|

          s.each do |k, v|

            override[k] << v

          end
        end

        override.each do |k, v|

          construct = {}
          capture   = {}

          override[k].each do |o|

            final.merge!( {k => {} } )

            available_methods = o.methods - Object.methods

            available_methods.each_with_index do |n, e|

              unless (n.to_s.end_with?("="))

                construct[n] = o.send(n)  unless o.send(n).nil?

              end

            end

            final[k] = capture.merge!( construct )

          end
        end
      end

      final

    end

  end
end