set :stages, %w(staging production)
set :default_stage, "staging"
require 'capistrano/ext/multistage'

require 'capistrano_colors'
require 'bundler/capistrano'

set :scm, :git
set :git_enable_submodules, true
set :deploy_via, :remote_cache
set :scm_verbose, true

set :run_options, { :pty => true }
set :ssh_options, { :forward_agent => true }
set :use_sudo, false

set :bundle_flags, "--deployment"
set :bundle_without, [:development, :test, :deployment]

on :start do
  `ssh-add`
end

require 'hoptoad_notifier/capistrano'

# Your code goes here
