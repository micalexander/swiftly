require 'yaml'
require 'swiftly/configure_all'
require 'swiftly/configure_local'
require 'swiftly/configure_staging'
require 'swiftly/configure_production'
require 'swiftly/app_module'

module Swiftly
  class Configure < Thor

    include Thor::Actions
    include Helpers

    desc "local [COMMAND]", "Configure local settings"
    subcommand "local", Local

    desc "staging [COMMAND]", "configure staging settings"
    subcommand "staging", Staging

    desc "production [COMMAND]", "configure production settings"
    subcommand "production", Production

    desc "all", "Configure all"
    subcommand "all", All

  end
end
