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

require 'shellwords'

module Cloudware
  class ReplacementFactory
    attr_reader :deployments, :deployment_name

    def initialize(cluster, deployment_name)
      @deployments = Models::Deployments.read(cluster)
      @deployment_name = deployment_name
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
        results = deployments.find_by_name(name)&.results || {}
        results[other_key.empty? ? key : other_key].to_s
      else
        value.to_s
      end
    end

    def build(input_string)
      split_build_string(input_string)
        .reject(&:nil?)
        .reduce({}) { |memo, str| memo.merge(parse(str)) }
        .to_h
        .merge(deployment_name: deployment_name)
    end

    private

    def parse(component_string)
      components = component_string.split('=', 2)
      unless components.length == 2
        raise InvalidInput, <<-ERROR.squish
          '#{component_string}' does not form a key value pair
        ERROR
      end
      keys, value = components
      keys.split(',').map do |key|
        [key.to_sym, parse_key_pair(key.to_sym, value)]
      end.to_h
    end

    def split_build_string(string)
      Shellwords.split(string || '')
    rescue ArgumentError => e
      raise InvalidInput, e.message
    end
  end
end
