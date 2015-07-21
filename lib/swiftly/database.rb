require 'Thor'
require 'swiftly/app_module'
require "thor/group"
require 'swiftly/project'
require 'open3'

module Swiftly
  class Database < Thor

    include Thor::Actions
    include Helpers

    no_commands do

      def initialize(project_name)

        @settings     = Project.settings( project_name )
        @project_name = project_name

      end

      def verify_db_credentials( environment, verbage )

        say #spacer
        say_status "#{APP_NAME}:", "Could not #{verbage} #{environment} database, because your credentials are not set.", :red if @settings[environment][:db_user].nil?

        say #spacer
        say_status "#{APP_NAME}:", "Could not #{verbage} #{environment} database, because your credentials are not set.", :red if @settings[environment][:db_host].nil?

        say #spacer
        say_status "#{APP_NAME}:", "Could not #{verbage} #{environment} database, because your credentials are not set.", :red if @settings[environment][:db_pass].nil?

        say #spacer
        say_status "#{APP_NAME}:", "Could not #{verbage} #{environment} database, because your credentials are not set.", :red if @settings[environment][:db_name].nil?

        abort if @settings[environment][:db_user].nil?
        abort if @settings[environment][:db_user].nil?
        abort if @settings[environment][:db_user].nil?
        abort if @settings[environment][:db_user].nil?

      end

      def dump( environment )

        verify_db_credentials environment, 'dump your'

        # provide the create dump site for the database dump
        dump_path = File.join( @settings[:project][:dump], environment.to_s )

        dump_file = "#{dump_path}/#{Time.now.strftime("%F-%H-%M-%S-%9N")}-#{environment}.sql"

        # check if the credentials environment provided was local and the ssh_status is set in order to dump using ssh or not
        if environment != :local && @settings[environment][:ssh_sql] != :disabled

          cmd = <<-EOF.unindent
            ssh \
            -C #{@settings[environment][:ssh_user]}@#{@settings[environment][:domain].gsub(/http:\/\//, '')} \
            mysqldump \
            --single-transaction \
            --opt \
            --net_buffer_length=75000 \
            --verbose \
            -u'#{@settings[environment][:db_user]}' \
            -h'#{@settings[environment][:db_host]}' \
            -p'#{@settings[environment][:db_pass]}' \
            '#{@settings[environment][:db_name]}' > \
            '#{dump_file}'
          EOF

          swiftly_shell cmd

        else

          cmd = <<-EOF.unindent
            mysqldump \
            --single-transaction \
            --opt --net_buffer_length=75000 \
            --verbose \
            -u'#{@settings[environment][:db_user]}' \
            -h'#{@settings[environment][:db_host]}' \
            -p'#{@settings[environment][:db_pass]}' \
            '#{@settings[environment][:db_name]}' > \
            '#{dump_file}'
          EOF

          swiftly_shell cmd

        end

        dump_file

      end

      def import( destination, import_file )

        verify_db_credentials destination, 'import into your'

        # dump the destination database first!
        dump( destination )

        # check if the destination destination provided was local and the ssh_status is set in order to dump using ssh or not
        if destination != :local && @settings[destination][:ssh_sql] != :disabled

          cmd = <<-EOF.unindent
            ssh \
            -C #{@settings[destination][:ssh_user]}@#{@settings[destination][:domain].gsub(/http:\/\//, '')} \
            mysql \
            -u'#{@settings[destination][:db_user]}' \
            -h'#{@settings[destination][:db_host]}' \
            -p'#{@settings[destination][:db_pass]}' \
            '#{@settings[destination][:db_name]}' \
            < '#{import_file}'
          EOF

          swiftly_shell cmd


        else

          cmd = <<-EOF.unindent
            mysql \
            -u'#{@settings[destination][:db_user]}' \
            -h'#{@settings[destination][:db_host]}' \
            -p'#{@settings[destination][:db_pass]}' \
            '#{@settings[destination][:db_name]}' < \
            '#{import_file}'
          EOF

          swiftly_shell cmd

        end

      end

      def sync( origin, destination, import_file = nil )

        verify_db_credentials origin,      'sync your'
        verify_db_credentials destination, 'sync your'

        # dump the origin database and return the file
        import_file = dump( origin ) unless import_file != nil

        import( destination, fix_serialization( update_urls(origin, destination, import_file ) ) )

      end

      def create( environment )

        verify_db_credentials environment, 'create a'

          cmd = <<-EOF.unindent
            mysql \
            -u'#{@settings[environment][:db_user]}' \
            -h'#{@settings[environment][:db_host]}' \
            -p'#{@settings[environment][:db_pass]}' \
            -Bse"CREATE DATABASE IF NOT EXISTS \
            #{@settings[environment][:db_name]}"
          EOF

          swiftly_shell cmd

      end

      def drop( environment )

        verify_db_credentials environment, 'drop your'

        cmd = <<-EOF.unindent
          mysql \
          -u'#{@settings[environment][:db_user]}' \
          -h'#{@settings[environment][:db_host]}' \
          -p'#{@settings[environment][:db_pass]}' \
          -Bse"DROP DATABASE IF EXISTS \
          #{@settings[environment][:db_name]}"
          EOF

          swiftly_shell cmd

      end

      def update_urls( origin, destination, import_file )

        # copy the file to the temp folder
        FileUtils.cp( import_file, File.join( @settings[:project][:dump], "temp") )

        # return the rewritten file
        return find_and_replace(
          input:   import_file,
          pattern: @settings[origin][:domain],
          output:  @settings[destination][:domain],
          file:    true
        )

      end
    end
  end
end