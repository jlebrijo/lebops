# Lebops

This is a Rails gem which normalizes the deployment life-cycle of Rails Web App.

Based on:
* RVM, Capistrano and Rake tasks.
* Different environments [development test vagrant staging production]
* Two differents repositories: Development and Client remotes

## Installation

Add this line to your application's Gemfile:

    gem 'lebops'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lebops

## Usage

### Prepare Capistrano Environments

Bundle and Capify with: capify .

Configure config/deploy.rb:

    set :application, "pet-contest"
    require 'lebops/deploy'

Create particular config for each environment in deploy/[staging.rb|vagrant.rb|production.rb]

Install application:

    cap [vagrant|production] app:setup

Update application:

    cap [vagrant|production] app:update

### Operation tasks

    rake app:db_reset                 # Reset and seed DataBase

    cap ops:console              # Open a console for the current stage
    cap ops:log                  # Tail the Rails log for the current stage
    cap ops:ssh                  # Open a ssh connection for the current stage

App server:

    cap thin:restart             # Restart server
    cap thin:setup               # Sets up Thin server environments
    cap thin:start               # Start server
    cap thin:stop                # Stop server

### Release Cycle

Releasing code:
* rake version:client_remote[git@bitbucket.org:jlebrijo/pet-contest.git] : create remote with client repo in local
** rake version:release[0.1.3] : For all remotes
** Merge (Fast Forward) origin:master / client_remote:master
* Create a tag with version number
* rake version:remove[0.1.3] : deletes version tag in all remotes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
