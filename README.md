# Swiftly 5.0.1 (formally known as Obi)

Swiftly is a web development project management tool.

## Features

1. Create projects swiftly on the fly
2. Deploy to multiple environments. Deployment is managed by [mina](https://github.com/mina-deploy/mina)
3. Will also push database to server while performing a find and replace on URLs
4. Backs up destination database on each push
5. Allows for rollback of database and files in the event that it becomes necessary
6. And much much more...

## Getting started

    $ gem install swiftly

Run it:

    $ swiftly <command> <args>

## Requirements

1. git (with username and email set)
2. mysql (or equivalent i.e. mariadb) 
3. php (to load the site, otherwise optional)
3. Apache/Nginx (to see the site, otherwise optional)

Git must be installed and username and email must be in your global config. Something like the below should do.

`$ git config --global user.name "Your Name"`
`$ git config --global user.email "your@mail.com"`

Mysql must be in your $PATH. You can check this by running:

    $ which mysql

This should yield something like:

    $ /opt/boxen/homebrew/bin/mysql

If nothing is displayed after running `which mysql` then you need to add it manually by running the following.

***Note that everything between `PATH=` and `:$PATH` in the command below, needs to be the absolute path to your mysql.***

    $ echo 'export PATH=/usr/local/mysql/bin:$PATH' >> ~/.bash_profile && source ~/.bash_profile

If all goes correctly, you should be able to run `which mysql` again, and it should yield the location of your mysql.

## Usage

Running `swiftly init` will walk you through setting up the basic settings necessary to get swiftly up and running.

    $ swiftly init

At this point you will be able to run `swiftly help` to get a list of commands and their arguments in order to interact with swiftly.

    $ swiftly help

Once you complete the interactive setup, a "Swiftlyfile" will be created in your sites directory. This file will contain your local settings and will look something like this:

~~~ruby

set :server, :type => :local do

  db_host 'localhost'
  db_user 'root'
  db_pass 'supersecurepassword'

end

~~~

The "Swiftlyfile" is used as a global config for your different server settings.

Currently the only server types that are recognized by swiftly are `:local`, `:staging`, and `:production`. *Eventually swiftly will allow for user specified server types!*

The `:staging` and `:production` server type settings can be overridden locally by adding a `config/config.rb` file in the root directory of an individual project. These server types except more parameters than just `db_host`, `db_user`, and `db_name` which are required in order to manage each project. Below is an example of a `config/config.rb` file using all possible parameters.

~~~ruby

set :server, :type => :staging do

  db_host  'localhost'
  db_user  'root'
  db_pass  'supersecurepassword'
  repo     'git@bitbucket.org:micalexander/micalexander.git'
  branch   'master'
  ssh_path '/var/www/micalexander_micalexander_com'
  ssh_user 'username'
  domain   'http://micalexander.micalexander.com'

end

set :server, :type => :production do

  db_host  'localhost'
  db_user  'root'
  db_pass  'supersecurepassword'
  repo     'git@bitbucket.org:micalexander/micalexander.git'
  branch   'master'
  ssh_path '/var/www/micalexander_com'
  ssh_user 'username'
  domain   'micalexander.com'

end

~~~

## Projects

Swiftly currently supports three types of projects, an `empty`, a `git` enabled, and a `wordpress` (git enabled) project.

Example folder structure:

~~~ruby

    project-name
        |
        |-- _resources // Not required. Opinionated organization
        |     |
        |     |-- assets
        |          |
        |          |-- architecture
        |          |-- doc
        |          |-- emails
        |          |-- fonts
        |          |-- images
        |          |-- raster
        |          |-- vector
        |
        |-- _backups // Required for automated backups of environments
        |     |
        |     |-- local
        |     |-- production
        |     |-- staging
        |     |-- temp
        |
        |-- .git // Not required but a good idea
        |     |
        |     |-- ...
        |
        |-- .gitignore // Not required but a good
        |
        |-- config // Required for project specific settings
              |
              |-- config.rb // Required for project specific settings
~~~

The above gives you an idea of what to expect when creating a project.

To create a project you can simply run:

    $ swiftly create [project_type] [project_name]

An `empty` project will include the structure in the diagram above with the exception of the .git directory, the .gitignore.

A `git` project will include everything in the diagram above.

A `wordpress` project will include everything in the diagram above with the addition of a full Wordpress installation.

## Wordpress

To install Wordpress as a project run the following command replacing "[project_name]" with your desired project name.

    $ swiftly create wordpress [project_name]

This will download Wordpress into a folder named "[project_name]", setup the Wordpress database for you, and automatically install a theme for you named "[project_name]".

By default the theme that will be installed into Wordpress will be [mask](https://github.com/micalexander/mask). This is because swiftly requires a customized "wp-config.php" file in order to setup the databases and manage the push and pulling of environments.

When using the customized "wp-config.php" file you will not need to include the `db_host`, `db_user`, `db_name` and `domain` parameters in the `config/config.rb` file. Doing so will override the "wp-config.php" file settings.

### Themes

You can tell swiftly what theme to use by following the syntax below. Keep in mind that your theme structure must match that of the [mask](https://github.com/micalexander/mask) theme in order for things to run smoothly.

The location parameter accepts a URL to a zip or a file path to a folder.

***Note the status parameter is set to `:disabled`, therefore it will be ignored and not installed. In order to have swiftly install this theme, remove the status altogether or set it to `:enabled`.***

~~~ruby
set :package, :type => :template do
  name     'mask'
  location 'https://github.com/micalexander/mask/archive/master.zip'
  status   :disabled
end
~~~

### Plugins

You can tell swiftly what plugin to use by following the syntax below.

The location parameter accepts a URL to a zip or a file path to a folder.

***Note the status parameter is set to `:disabled`, therefore it will be ignored and not installed. In order to have swiftly install this plugin, remove the status altogether or set it to `:enabled`.***

~~~ruby
set :package, :type => :plugin do
  name     'advanced-custom-fields-pro'
  location '/Users/username/plugins'
  status   :disabled
end
~~~

*More examples coming...*
