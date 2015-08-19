require 'thor'
require 'json'
require 'swiftly/app_module'
require 'swiftly/config'
require 'swiftly/create'
require 'swiftly/push'
require 'swiftly/pull'
require 'swiftly/ssh'
require 'swiftly/clean'
require 'swiftly/setup'
require 'swiftly/rollback'
require 'swiftly/destroy'

module Swiftly
  class CLI < Thor

    include Thor::Actions
    include Helpers

    register Swiftly::Create,    "create",    "create COMMAND PROJECT_NAME",           "Create projects by passing a project name"
    register Swiftly::Setup,     "setup",     "setup COMMAND PROJECT_NAME",            "Setup [environment] on server"
    register Swiftly::Push,      "push",      "push COMMAND PROJECT_NAME",             "Push [environment] database and files to server"
    register Swiftly::Pull,      "pull",      "pull COMMAND PROJECT_NAME",             "Pull [environment] database and files to local"
    register Swiftly::Rollback,  "rollback",  "rollback COMMAND PROJECT_NAME",         "Rollback the [environment] database and files on server"
    register Swiftly::SSH,       "ssh",       "ssh COMMAND PROJECT_NAME",              "SSH into the [environment] server and cd into site path"
    register Swiftly::Clean,     "clean",     "clean COMMAND PROJECT_NAME",            "Clean the [environment] releases on server"
    register Swiftly::Destroy,   "destroy",   "destroy PROJECT_NAME",                  "Destroy local project!"

  end
end
