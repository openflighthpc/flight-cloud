
# frozen_string_literal: true

ENV['CLOUDWARE_DEBUG'] = 'true'

task :setup do
  ENV['BUNDLE_GEMFILE'] = File.join(__dir__, 'Gemfile')

  require 'rubygems'
  require 'bundler'

  Bundler.setup(:development)
  require 'pp'
  require 'pry'
  require 'pry-byebug'

  Bundler.setup(:default, :config, :aws, :azure)

  $LOAD_PATH.unshift(File.join(__dir__, 'lib'))
  require 'cloudware'
end

task console: :setup do
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

task :profile do
  Bundler.setup(:development)
  require 'pilfer'

  io = StringIO.new
  reporter = Pilfer::Logger.new(io)
  profiler = Pilfer::Profiler.new(reporter)

  $LOAD_PATH << File.join(__dir__, 'lib')
  profiler.profile('require') do
    require 'cloudware'
  end

  io.rewind
  puts io.read
end
