# rails new app_name -d mysql -m path/to/this/template.rb

def template_path(path)
  @templates_folder ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  File.join(@templates_folder, path)
end

# Gemfile
gsub_file 'Gemfile', "gem 'mysql2'", "gem 'mysql2', '~> 0.2.0'"
inject_into_file 'Gemfile', File.read(template_path('Gemfile')), { :before => '# Use unicorn as the web server', :verbose => false }

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
application <<EOF
  config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.integration_tool :rspec
    end
EOF

remove_file 'app/views/layouts/application.html.erb'
copy_file template_path('sass.rb'), 'config/initializers/sass.rb'
copy_file template_path('haml.rb'), 'config/initializers/haml.rb'
copy_file template_path('gitignore'), '.gitignore'
copy_file template_path('spec_helper.rb'), 'spec/spec_helper.rb'
copy_file template_path('acceptance_helper.rb'), 'spec/acceptance/acceptance_helper.rb'
copy_file template_path('production.rb'), 'config/deploy/production.rb'
copy_file template_path('staging.rb'), 'config/deploy/staging.rb'
copy_file template_path('rspec'), '.rspec'
copy_file template_path('autotest'), '.autotest' if RUBY_PLATFORM.downcase.include?('darwin')
run "cp config/environments/production.rb config/environments/staging.rb"

gsub_file 'config/deploy.rb', 'set :scm, :subversion', '# set :scm, :subversion'
prepend_file 'config/deploy.rb', File.read(template_path('deploy.rb'))

hoptoad_api_key = ask("What's your Hoptoad API key?")
if hoptoad_api_key.present?
  generate 'hoptoad', "--api-key #{hoptoad_api_key}"
end

git :init
git :add => ".", :commit => "-m 'initial commit'"

