require "thor/group"
require 'rubygems'
require 'active_support'
require 'active_support/core_ext/string'

module Swiftly
  class GeneratePostType < Thor::Group

    include Thor::Actions

    argument     :post_type_name
    argument     :post_type_filter
    argument     :project

    desc "Handles the creation of the post type file."

    def self.source_root
      File.dirname(__FILE__)
    end

    def create()

      if @post_type_filter == 'published-date' or @post_type_filter == ''

        @filter          = '&int-year=$matches[1]&int-month=$matches[2]'
        @taxonomy_filter = '=$matches[1]&int-year=$matches[2]$&int-month=$matches[3]'
        @filter_regexp   = '(\d{4})/(\d{2})/??'

      elsif @post_type_filter == 'last-name'

        @post_type_filter = '&letter=$matches[1]'
        @filter_regexp    = '([A-Z])/??$'

      elsif @post_type_filter == 'start-date'

        @post_type_filter = '&month=$matches[1]'
        @filter_regexp    = '(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)/?$'

      else

        say "\nswiftly: filter type \"#{@post_type_filter}\" unaccepted\n\n", :red
        exit

      end

      template File.join( 'templates', 'post_type.erb' ), File.join( "#{@project[:path]}", 'wp-content', 'plugins', "#{@project[:name]}-specific-plugin", 'custom-post-types',"#{@post_type_name.pluralize}.php")

    end
  end
end