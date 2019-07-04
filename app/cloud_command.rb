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

require 'active_support/core_ext/module/delegation'
require 'open3'

module App
  CloudCommand = Struct.new(:stdout, :stderr, :status) do
    BASE = 'flight cloud aws'

    ['status', 'on', 'off'].each do |type|
      define_singleton_method("power_#{type}") do |node, group: false|
        capture3("power #{type} #{node} #{'--group' if group}")
      end
    end

    private_class_method

    def self.capture3(raw_cmd, *a)
      cmd = "#{BASE} #{raw_cmd}"
      Bundler.with_clean_env do
        stdout, stderr, status = Open3.capture3(cmd, *a)
        new(
          stdout.chomp,
          stderr.chomp.sub(/\Aerror: /, ''),
          status
        )
      end
    end

    delegate :success?, to: :status

    def response
      {
        success: success?,
      }.tap do |h|
        success? ? h[:message] = stdout : h[:error] = stderr
      end
    end
  end
end
