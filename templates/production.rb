set :rails_env, "production"
set :branch, "production"
server "your production server here", :app, :web, :db, :primary => true

# set :application, "set your application name here"
# set :deploy_to, "/your/deploy/path"
# set :user, "deployer"
