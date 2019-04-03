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

require 'yaml'
require 'fileutils'

module Cloudware
  class Data
    DEFAULT_VALUE = {}.freeze

    class << self
      def load(file, default_value: DEFAULT_VALUE)
        data = if file.is_a?(IO)
                 file.read
               elsif File.exist?(file)
                 File.read(file)
               else
                 ''
               end
        load_string(data, default_value: default_value)
      end

      def load_string(string, default_value: DEFAULT_VALUE)
        raw = convert_keys(YAML.load(string))
        raw ? raw : default_value
      end

      def dump(file, data)
        FileUtils.mkdir_p(File.dirname(file))
        File.write(file, YAML.dump(data))
      end

      private

      def convert_keys(obj)
        case obj
        when Hash
          obj.deep_symbolize_keys
        when Enumerable
          obj.map { |sub_obj| convert_keys(sub_obj) }
        else
          obj
        end
      end
    end
  end
end
