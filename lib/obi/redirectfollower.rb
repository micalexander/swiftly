require 'net/http'

module Obi
    class RedirectFollower
        class TooManyRedirects < StandardError; end

        attr_accessor :url, :body, :redirect_limit, :response

        def initialize(url, limit=5)
            @url, @redirect_limit = url, limit
        end

        def check_url(url)
            uri = URI(url)
            request = Net::HTTP.new uri.host
            response= request.request_head uri.path
            puts response.code.to_i
            return response.code.to_i == 200 || response.code.to_i == 301
        end

        def resolve
            # if self.check_url(@url) == true
                raise TooManyRedirects if redirect_limit < 0

                self.response = Net::HTTP.get_response(URI.parse(url))

                if response.kind_of?(Net::HTTPRedirection)
                  self.url = redirect_url
                  self.redirect_limit -= 1

                  resolve
                end

                self.body = response.body
                self
            # else
            #     puts self.check_url(@url)
            #     puts "\nobi: Resource could not be found: \n\t#{@url}\n\n"
            #     exit
            # end
        end

        def redirect_url
            if response['location'].nil?
                response.body.match(/<a href=\"([^>]+)\">/i)[1]
            else
                response['location']
            end
        end
    end
end