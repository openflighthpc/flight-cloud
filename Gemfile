# frozen_string_literal: true

source 'https://rubygems.org'

gem 'activemodel'
gem 'aws-sdk-cloudformation'
gem 'aws-sdk-ec2'
gem 'azure_mgmt_compute'
gem 'azure_mgmt_resources'
gem 'colorize'
gem 'commander-openflighthpc'
gem 'flight_manifest', '~>0.1.3'
gem 'hashie'
gem 'ipaddr'
gem 'memoist'
gem 'parallel'
gem 'rake'
gem 'require_all'
gem 'rubyzip'
gem 'tty-editor'
gem 'tty-markdown'
gem 'tty-spinner'
gem 'tty-table'
gem 'tty-prompt'

group :config do
  gem 'activesupport'
  gem 'flight_config'
end

group :server do
  gem 'sinatra'
  gem 'sinatra-namespace'
  gem 'sinatra-param'
  gem 'webrick'
end

group :development do
  gem 'factory_bot'
  gem 'fakefs'
  gem 'pilfer'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rake'
  gem 'rspec'
  gem 'rspec-wait'
  gem 'rubocop', '~> 0.52.1', require: false
  gem 'rubocop-rspec'
end
