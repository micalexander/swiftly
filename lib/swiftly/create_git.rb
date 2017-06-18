require "thor/group"
require 'rubygems'
require 'active_support'
require 'active_support/core_ext/string'
require 'git'

module Swiftly
  class CreateGit < Thor::Group

    include Thor::Actions

    argument :project_path

    desc "Handles the creation of a git project."

    def self.source_root

      File.dirname(__FILE__)

    end

    def create_git()

      git = Git.init( @project_path )

      template(
        File.join(
          'templates',
          'gitignore.erb'
        ),
        File.join( @project_path, '.gitignore' )
      ) unless File.exists? File.join( @project_path, '.gitignore' )


      git.add

      if  !git.config('user.name').empty?

        git.commit_all('initial commit')
      else

        say_status "#{APP_NAME}:", "Unable to create an initial git commit. Please set your git global user.email and user.name in order to create your first commit", :yellow
      end


    end
  end
end
