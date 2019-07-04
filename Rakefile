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

    Bundler.setup(:default)

    require 'cloudware'
  rescue => e
    $stderr.puts e.message
    exit 1
  end
end

# Old rake task. Reinstate as necessary
# ENV['CLOUDWARE_DEBUG'] = 'true'

# task :setup do
#   ENV['BUNDLE_GEMFILE'] = File.join(__dir__, 'Gemfile')

#   require 'rubygems'
#   require 'bundler'

#   Bundler.setup(:development)
#   require 'pp'
#   require 'pry'
#   require 'pry-byebug'

#   Bundler.setup(:default, :config, :aws, :azure)

#   $LOAD_PATH.unshift(File.join(__dir__, 'lib'))
#   require 'cloudware'
# end

# task console: :setup do
#   Pry::REPL.start({})
# end

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
