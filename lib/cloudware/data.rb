# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

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
