# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

task :'setup:server' do
  ENV['CLOUDWARE_SERVER_MODE'] = 'true'
  Rake::Task[:setup].invoke
  $: << Cloudware::Config.root_dir
end

task :setup do
  lib_dir = File.join(__dir__, 'lib')
  $LOAD_PATH << File.join(lib_dir)
  ENV['BUNDLE_GEMFILE'] ||= File.join(__dir__, 'Gemfile')

  Thread.report_on_exception = false

  require 'rubygems'
  require 'bundler'

  # Catch any config errors during the require/setup
  begin
    # Require the config and associated gems
    Bundler.require(:config)
    require 'cloudware/config'

    # Require the development gems
    if Cloudware::Config.debug
      # `pry` needs to be required in a specific order so it doesn't clash with `pp`
      Bundler.setup(:development)
      require 'pp'
      require 'pry'
      require 'pry-byebug'
    end

    sections = [:default]
    sections.push(:server) if ENV['CLOUDWARE_SERVER_MODE']
    Bundler.setup(*sections)

    require 'cloudware'
  rescue => e
    $stderr.puts e.message
    exit 1
  end
end

task :console do
  ENV['CLOUDWARE_DEBUG'] = 'true'
  Rake::Task[:setup].invoke
  binding.pry
end

task :'token:generate', [:exp] => [:setup] do |_, args|
  args.with_defaults(exp: '30')
  require 'jwt'
  require 'active_support/core_ext/numeric/time'
  data = { exp: args.exp.to_i.days.from_now.to_i }
  puts JWT.encode(data, Cloudware::Config.jwt_shared_secret, 'HS256')
end

# task :spin do
#   include Cloudware::WithSpinner
#   result = with_spinner('Spinning') do
#     sleep 10
#     'I am the results string'
#   end
#   puts result
# end

# task :profile do
#   Bundler.setup(:development)
#   require 'pilfer'

#   io = StringIO.new
#   reporter = Pilfer::Logger.new(io)
#   profiler = Pilfer::Profiler.new(reporter)

#   $LOAD_PATH << File.join(__dir__, 'lib')
#   ARGV = []
#   profiler.profile('require') do
#     require 'cloudware'
#     Cloudware::CLI.run!
#   end

#   io.rewind
#   puts io.read
# end
