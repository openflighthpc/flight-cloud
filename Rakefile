
# frozen_string_literal: true

ENV['CLOUDWARE_DEBUG'] = 'true'
require_relative 'lib/cloudware.rb'

task :console do
  Pry::REPL.start({})
end

task :spin do
  include Cloudware::WithSpinner
  result = with_spinner('Spinning') do
    sleep 10
    'I am the results string'
  end
  puts result
end
