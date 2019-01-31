# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activemodel'
gem 'colorize'
gem 'commander', git: 'https://github.com/alces-software/commander'
gem 'hashie'
gem 'ipaddr'
gem 'memoist'
gem 'parallel'
gem 'require_all'
gem 'tty-markdown'
gem 'tty-spinner'
gem 'tty-table'

group :config do
  gem 'activesupport'
  gem 'flight_config', git: 'https://github.com/alces-software/flight_config'
end

group :aws do
  gem 'aws-sdk-cloudformation'
  gem 'aws-sdk-ec2'
end

group :azure do
  gem 'azure_mgmt_compute'
  gem 'azure_mgmt_resources'
end

group :development do
  gem 'factory_bot'
  gem 'fakefs'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec'
  gem 'rspec-wait'
  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rubocop-rspec'
end
