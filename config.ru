# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2019-present OpenFlightHPC
#
# This file is part of flight-cloud
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with this project. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight-cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

require 'rake'
load File.join(__dir__, 'Rakefile')

Rake::Task[:'setup:server'].invoke

# Insure the current cluster exists before starting the server
# NOTE: $PROGRAM_NAME is changed so the error message is correct
old_name = $PROGRAM_NAME
$PROGRAM_NAME = 'cloud'
Cloudware::CommandConfig.read.current_cluster
$PROGRAM_NAME = old_name


# Require the app
require 'app/routes'

# Sets up the ssl options
require 'webrick'
require 'webrick/https'

base_options = {
  Port: 443,
  SSLEnable: true
}

ssl_options = if Cloudware::Config.ssl_private_key? && Cloudware::Config.ssl_certificate?
  base_options.merge(
    SSLCertificate: OpenSSL::X509::Certificate.new(Cloudware::Config.read_ssl_certificate),
    SSLPrivateKey: OpenSSL::PKey::RSA.new(Cloudware::Config.read_ssl_private_key)
  )
else
  puts <<~MSG.squish
    Could not locate either the ssl certificate or private key. Defaulting to a
    self signed certificate
  MSG
  base_options.merge(SSLCertName: [ %w[CN localhost] ])
end

# Run the server using webrick
server = WEBrick::HTTPServer.new(ssl_options)
server.mount '/', Rack::Handler::WEBrick, App::Routes.new
server.start

