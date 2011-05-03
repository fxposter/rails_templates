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
