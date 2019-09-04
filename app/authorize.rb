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

#
# This rack middleware has been adapted from:
# https://auth0.com/blog/ruby-authentication-secure-rack-apps-with-jwt/
#

require 'jwt'
require 'cloudware/config'

# Ensures the shared secret has been set
Cloudware::Config.jwt_shared_secret

module App
  class Authorize
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      if token = extract_token(env)
        options = { algorithm: 'HS256' } # .merge(iss: ENV['JWT_ISSUER'])
        JWT.decode(token, Cloudware::Config.jwt_shared_secret, true, options)
        app.call(env)
      else
        [401, { 'Content-Type' => 'text/plain' }, ['An authorization token must be provided with the request']]
      end
    rescue JWT::ExpiredSignature
      [403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']]
    # Ignoring the issuer of the token for the time being
    # rescue JWT::InvalidIssuerError
    #   [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']]
    rescue JWT::InvalidIatError
      [403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']]
    rescue JWT::VerificationError
      [401, { 'Content-Type' => 'text/plain' }, ['Unrecognized authorization token signature']]
    rescue JWT::DecodeError
      [401, { 'Content-Type' => 'text/plain' }, ['An error occurred when decoding the authorization token']]
    rescue
      [500, { 'Content-Type' => 'text/plain' }, ['An unexpected error has occurred during authorization']]
    end

    private

    def extract_token(env)
      env.fetch('HTTP_AUTHORIZATION', '').split(' ', 2).last
    end
  end
end
