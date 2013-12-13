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
			@match_2 = ''
			if options[:filter_by] == 'published-date' or options[:filter_by] == ''
				@filter_by = '&int-year=$matches[1]$&int-month=$matches[2]'
				@taxonomy_filter_by = '=$matches[1]&int-year=$matches[2]$&int-month=$matches[3]'
				@filter_by_regexp = '(\d{4})/(\d{2})/??'
			elsif options[:filter_by] == 'last-name'
				@filter_by = '&letter=$matches[1]'
				@filter_by_regexp = '([A-Z])/??$'
			elsif options[:filter_by] == 'start-date'
				@filter_by = '&month=$matches[1]'
				@filter_by_regexp = '(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/?$'
			else
				say "\nobi: filter type \"#{options[:filter_by]}\" unaccepted\n", :red
				exit
			end

			template File.join( 'templates', 'post_type_rewrite.erb' ), File.join( "#{project_path}", 'wp-content', 'plugins', "#{project_name}-specific-plugin", 'custom-post-types',"#{post_type.pluralize}.php")
		end
	end
end