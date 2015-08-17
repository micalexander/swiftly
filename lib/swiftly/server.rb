require "swiftly/factory"

module Swiftly
  class Server

    attr_accessor :domain
    attr_accessor :repo
    attr_accessor :branch
    attr_accessor :ssh_path
    attr_accessor :ssh_user
    attr_accessor :db_name
    attr_accessor :db_host
    attr_accessor :db_user
    attr_accessor :db_pass

  end
end