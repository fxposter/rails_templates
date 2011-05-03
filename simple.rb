# rails new app_name -d mysql -m path/to/this/template.rb

# Gemfile
gsub_file 'Gemfile', "gem 'mysql2'", "gem 'mysql2', '~> 0.2.0'"
gemfile = <<EOF
gem 'haml'
gem 'sass'
gem 'compass'
gem 'html5-boilerplate'

gem 'jquery-rails'
gem 'rails3-generators'
gem 'haml-rails'
gem 'meta_where'

gem 'hoptoad_notifier'

group :development, :test do
  gem 'ruby-debug'

  gem 'autotest-standalone'
  gem 'autotest-rails-pure'
  # gem 'autotest-fsevent', :require => false
  # gem 'autotest-growl', :require => false

  gem 'rspec-rails', '~> 2.5.0'
  gem 'shoulda-matchers'
  gem 'factory_girl_rails', :require => false
  gem 'capybara'
  gem 'database_cleaner'
  gem 'spork', '~> 0.9.0.rc'
  gem 'launchy' # So you can do Then show me the page
  gem 'timecop'
  gem 'steak'
end

group :deployment do
  gem 'capistrano'
  gem 'capistrano-ext'
  gem 'capistrano_colors'
  # Contains bugs not fixed by author
  # gem 'dark-capistrano-recipes'
  # gem 'dark-capistrano-recipes', :git => 'git://github.com/daemon/capistrano-recipes.git'
end

group :console do
  gem 'wirble'
  gem 'hirb'
  gem 'awesome_print', :require => 'ap'
  gem 'looksee', :require => 'looksee'
end

EOF
inject_into_file 'Gemfile', gemfile, { :before => '# Use unicorn as the web server', :verbose => false }

# installing gems
run "bundle"
run "compass init rails -r html5-boilerplate -u html5-boilerplate --force"
run "gem install autotest-fsevent autotest-growl" if RUBY_PLATFORM.downcase.include?('darwin')
generate "rspec:install"
generate "steak:install"
run "spork --bootstrap"
generate 'jquery:install', '--version 1.6'
capify!

# application settings
remove_file 'app/views/layouts/application.html.erb'

application <<EOF
  config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.integration_tool :rspec
    end
EOF

initializer 'sass.rb', <<EOF
Sass::Plugin.options[:style] = :compact
Sass::Plugin.options[:line_numbers] = false
Sass::Plugin.options[:line_comments] = false
Sass::Plugin.options[:debug_info] = false
EOF

initializer 'haml.rb', <<EOF
Haml::Template::options[:ugly] = true
Haml::Template.options[:attr_wrapper] = '"'
EOF

file  '.gitignore', <<EOF
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
.DS_Store
db/schema.rb
.svn
.*sw*
.bundle/
.idea/
public/stylesheets/
test/
nbproject/
*.tmproj
.metadata/
.project
tmp/
EOF

file 'spec/spec_helper.rb', <<EOF
require 'rubygems'
require 'spork'

Spork.prefork do
  # Loading more in this block will cause your tests to run faster. However,
  # if you change any configuration or code from libraries loaded here, you'll
  # need to restart spork for it take effect.
  ENV["RAILS_ENV"] ||= 'test'
  require File.expand_path("../../config/environment", __FILE__)
  require 'rspec/rails'

  require 'shoulda'
  require 'factory_girl'
  require 'database_cleaner'

  # Requires supporting ruby files with custom matchers and macros, etc,
  # in spec/support/ and its subdirectories.
  Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

  RSpec.configure do |config|
    # == Mock Framework
    #
    # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
    #
    # config.mock_with :mocha
    # config.mock_with :flexmock
    # config.mock_with :rr
    config.mock_with :rspec

    # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
    config.fixture_path = "\#{::Rails.root}/spec/fixtures"

    # If you're not using ActiveRecord, or you'd prefer not to run each of your
    # examples within a transaction, remove the following line or assign false
    # instead of true.
    config.use_transactional_fixtures = false
    config.use_instantiated_fixtures  = false

    config.before :suite do
      DatabaseCleaner.strategy = :transaction
      DatabaseCleaner.clean_with :truncation
    end

    config.before :each do
       DatabaseCleaner.start
    end

    config.after :each do
       DatabaseCleaner.clean
    end
  end
end

Spork.each_run do
  # This code will be run each time you run your specs.  
  require 'factory_girl_rails'
end
EOF

file 'spec/acceptance/acceptance_helper.rb', <<EOF
require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

Spork.prefork do
  require 'steak'
  require 'capybara/rails'
  require 'capybara/rspec'

  Capybara.javascript_driver = :selenium
  Capybara.default_selector = :css
  Capybara.default_wait_time = 5

  RSpec.configure do |config|
    config.before :all, :type => :acceptance do
      DatabaseCleaner.strategy = :truncation
    end

    config.after :all, :type => :acceptance do
      DatabaseCleaner.strategy = :transaction
    end
  end

  # If you use thinking-sphinx - uncomment lines below
  # require 'thinking_sphinx/test'
  # ThinkingSphinx::Test.init

  # Put your acceptance spec helpers inside /spec/acceptance/support
  Dir["\#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
end
EOF

file 'config/deploy/production.rb', <<EOF
set :rails_env, "production"
set :branch, "production"
server "your production server here", :app, :web, :db, :primary => true

# set :application, "set your application name here"
# set :deploy_to, "/your/deploy/path"
# set :user, "deployer"
EOF

file 'config/deploy/staging.rb', <<EOF
set :rails_env, "staging"
set :branch, "master"
server "your staging server here", :app, :web, :db, :primary => true

# set :application, "set your application name here"
# set :deploy_to, "/your/deploy/path"
# set :user, "deployer"
EOF

file '.rspec', <<EOF
--colour
--drb
--format documentation
EOF

if RUBY_PLATFORM.downcase.include?('darwin')
  file '.autotest', <<-EOF
  if RUBY_PLATFORM =~ /darwin/
    require 'autotest/growl'
    require 'autotest/fsevent'
  end
  EOF
end

run "cp config/environments/production.rb config/environments/staging.rb"

gsub_file 'config/deploy.rb', 'set :scm, :subversion', '# set :scm, :subversion'
prepend_file 'config/deploy.rb', <<EOF
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

EOF

hoptoad_api_key = ask("What's your Hoptoad API key?")
if hoptoad_api_key.present?
  generate 'hoptoad', "--api-key #{hoptoad_api_key}"
end

git :init
git :add => ".", :commit => "-m 'initial commit'"
