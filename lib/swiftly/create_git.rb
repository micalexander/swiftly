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
      git.commit_all('initial commit')

    end
  end
end