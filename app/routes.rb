# frozen_string_literal: true
#==============================================================================
# Copyright (C) 2019-present OpenFlightHPC
#
# This file is part of management-server
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
# For more information on flight-account, please visit:
# https://github.com/openflighthpc/management-server
#===============================================================================

require 'sinatra/base'
require 'sinatra/namespace'
require 'sinatra/json'
require 'sinatra/param'
require 'app/cloud_command'

module App
  class Routes < Sinatra::Base
    register Sinatra::JSON
    register Sinatra::Namespace
    helpers  Sinatra::Param

    get '/' do
      'openFlightHPC - Next generation HPC on any platform'
    end

    namespace '/power/:node' do
      get '' do
        json CloudCommand.power_status(node_param, group: group_param)
                         .response
      end

      get '/on' do
        json CloudCommand.power_on(node_param, group: group_param)
                         .response
      end

      get '/off' do
        json CloudCommand.power_off(node_param, group: group_param)
                         .response
      end
    end

    private

    def node_param
      params[:node]
    end

    def group_param
      param :group, Boolean
    end
  end
end

