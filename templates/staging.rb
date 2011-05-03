set :rails_env, "staging"
set :branch, "master"
server "your staging server here", :app, :web, :db, :primary => true

# set :application, "set your application name here"
# set :deploy_to, "/your/deploy/path"
# set :user, "deployer"
