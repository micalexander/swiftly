require "thor/group"
require 'rubygems'
require 'active_support'
require 'active_support/core_ext/string'

module Obi
	class PostType < Thor::Group

		include Thor::Actions

		argument :project_name
		argument :post_type
		argument :project_path
		class_option :filter_by

		desc "Handles the creation of the post type file."

		def self.source_root
			File.dirname(__FILE__)
		end

		def create_post

			if options[:filter_by] == 'published-date' or options[:filter_by] == ''
				@filter_by = :published_date
			elsif options[:filter_by] == 'last-name'
				@filter_by = :letter
				@filter_by_regexp = '([A-Z])/??$'
				rewrite = true
			elsif options[:filter_by] == 'start-date'
				@filter_by = :month
				@filter_by_regexp = '(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/?$'
				rewrite = true
			else
				say "\nobi: filter type \"#{options[:filter_by]}\" unaccepted\n", :red
				exit
			end

			if rewrite
				template File.join( 'templates', 'post_type_rewrite.erb' ), File.join( "#{project_path}", 'wp-content', 'plugins', "#{project_name}-specific-plugin", "#{post_type}","#{post_type}.php")
			else
				template File.join( 'templates', 'post_type.erb' ), File.join( "#{project_path}", 'wp-content', 'plugins', "#{project_name}-specific-plugin", 'custom-post-types',"#{post_type}.php")
			end
		end
	end
end