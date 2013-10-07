require 'net/http'
require 'fileutils'

module Obi
    class Project

        @@config_settings = Obi::Configuration.settings
        class RedirectFollower
            class TooManyRedirects < StandardError; end

            attr_accessor :url, :body, :redirect_limit, :response

            def initialize(url, limit=5)
                @url, @redirect_limit = url, limit
            end

            def resolve
                raise TooManyRedirects if redirect_limit < 0

                self.response = Net::HTTP.get_response(URI.parse(url))

                if response.kind_of?(Net::HTTPRedirection)
                  self.url = redirect_url
                  self.redirect_limit -= 1

                  resolve
                end

                self.body = response.body
                self
            end

            def redirect_url
                if response['location'].nil?
                    response.body.match(/<a href=\"([^>]+)\">/i)[1]
                else
                    response['location']
                end
            end
        end

        def create_directories(directory_name)
            pre_path_str = File.join( @@config_settings['local_project_directory'], directory_name)
            if !File.directory?(pre_path_str)
                path_str = "parent_folder/sub_dir/{ai,architecture,content,emails,estimates,fonts,gif,jpg,pdf,png,psd}"
                le_paths = path_str.match(/\{(.*)\}/)[1].split(',').map {|s| "#{pre_path_str}/_resources/assets/" << s }
                FileUtils.mkdir_p le_paths , {:noop => false, :verbose => false}
            else
                puts ""
                puts "obi: There is already a project with that name. Please try again."
                puts ""
            end
        end

        def wordpress(directory_name)
            create_directories(directory_name)
            wordpress = RedirectFollower.new('http://wordpress.org/latest.zip').resolve
            File.open(File.join( @@config_settings['local_project_directory'], directory_name, "latest.zip"), "w") do |file|
                file.write wordpress.body
            end
        end
    end
end



