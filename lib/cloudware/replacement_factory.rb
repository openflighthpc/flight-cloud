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

module Cloudware
  class ReplacementFactory
    attr_reader :context

    def initialize(context)
      @context = context
    end

    #
    # parse_key_pair:
    #
    # Determine the replacement value for a specific key pair, as this is the
    # fundamental component of the `ReplacementFactory`, it is part of the
    # public interface. This allows its behaviour to be tested
    #
    def parse_key_pair(key, value)
      return '' if value.nil? || value.empty?
      if value[0] == '*'
        name = /(?<=\A\*)[^\.]*/.match(value).to_s
        other_key = /(?<=\.).*/.match(value).to_s.to_sym
        results = context.find_deployment(name)&.results || {}
        results[other_key.empty? ? key : other_key].to_s
      else
        value.to_s
      end
    end

    def build(input_string)
      parse(input_string)
    end

    private

    def parse(component_string)
      component_string.split('=', 2).tap do |array|
        raise InvalidInput, <<-ERROR.squish unless array.length == 2
          '#{component_string}' does not form a key value pair
        ERROR
        array[0] = array[0].to_sym
        array[1] = parse_key_pair(array[0], array[1])
      end
    end
  end
end
