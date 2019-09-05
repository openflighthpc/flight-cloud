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

require 'cloudware/models/application'
require 'cloudware/models/concerns/provider_client'

module Cloudware
  module Models
    class Machine < Application
      class << self
        def flag
          'TAG'
        end

        #
        # Extracts the models name from a tag
        #
        # Valid tags are given in the format:
        # <name>TAG<tag>
        #
        # The regex matches the '<name>' component of the above tag if the
        # syntax is correct, otherwise it returns nil.
        #
        # It therefore can also be used to filter out arbitrary tags from
        # model tags
        #
        # Examples:
        #   name_from_tag('node01TAGsome-key') => 'node01'
        #   name_from_tag('some-other-string') =>  nil
        #
        def name_from_tag(tag)
          regex = /\A.*(?=#{flag}.*\Z)/
          regex.match(tag.to_s)&.to_a&.first
        end

        def tag_generator(name, tag)
          :"#{name}#{flag}#{tag}"
        end
      end

      include Concerns::ProviderClient

      PROVIDER_ID_FLAG = 'ID'
      GROUPS_TAG = 'groups'

      delegate :region, :provider, to: :cluster

      attr_accessor :name, :cluster

      def initialize(cluster:, name:)
        @cluster = Cluster.read(cluster)
        super(name: name)
      end

      def provider_id
        fetch_result(PROVIDER_ID_FLAG)
      end

      def groups
        fetch_result(GROUPS_TAG, default: '').split(',')
      end

      def deployment
        cluster.__registry__.read(Models::Node, cluster.identifier, name)
      end

      def tags
        (deployment.results || {}).each_with_object({}) do |(key, value), memo|
          next unless (tag = extract_tag(key))
          memo[tag] = value
        end
      end

      def tag_generator(tag)
        self.class.tag_generator(name, tag)
      end

      #
      # Extract the tag component from the key
      #
      # Valid tags are given in the format:
      # <name>TAG<tag>
      #
      # The regex matches the `<tag>` component of the above tag if the
      # syntax matches with the correct name. Otherwise it returns `nil`
      #
      # Examples:
      #
      #   extract_tag('mynodeTAGkey')        => 'key'
      #   extract_tag('differentnodeTAGkey') =>  nil
      #   extract_tag('random-string')       =>  nil
      #
      def extract_tag(key)
        regex = /(?<=\A#{self.class.tag_generator(Regexp.escape(name), '')}).*/
        regex.match(key.to_s)&.to_a&.first&.to_sym
      end

      def fetch_result(short_tag, default: nil)
        long_tag = tag_generator(short_tag)
        result = (deployment.results || {})[long_tag]
        return result unless result.nil?
        return default unless default.nil?
        yield long_tag if block_given?
      end

      def machine_client
        id = provider_id
        provider_client.machine(id) if id
      end
      memoize :machine_client
    end
  end
end
