
require_relative 'lib/cloudware.rb'

task :spin do
  include Cloudware::WithSpinner
  result = with_spinner('Spinning') do
    sleep 10
    'I am the results string'
  end
  puts result
end
