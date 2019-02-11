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

require 'cloudware/models/application'
require 'cloudware/models/concerns/provider_client'

module Cloudware
  module Models
    class Machine < Application
      class << self
        def flag
          'TAG'
        end

        def build_from_context(context)
          (context.results || {})
            .keys
            .map { |k| name_from_tag(k) }
            .uniq
            .reject(&:nil?)
            .map do |name|
            new(name: name, context: context)
          end
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

      delegate :status, :off, :on, to: :machine_client
      delegate :region, :provider, to: :cluster

      attr_accessor :name, :cluster

      def initialize(cluster:, name:)
        @cluster = Cluster.read(cluster)
        super(name: name)
      end

      def provider_id
        fetch_result(PROVIDER_ID_FLAG) do |long_tag|
          raise ModelValidationError, <<-ERROR.squish
            Machine '#{name}' is missing its provider ID. Make sure
            '#{long_tag}' is set within the deployment output
          ERROR
        end
      end

      def groups
        fetch_result(GROUPS_TAG, default: '').split(',')
      end

      def tags
        (cluster.deployments.results || {}).each_with_object({}) do |(key, value), memo|
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
        result = (cluster.deployments.results || {})[long_tag]
        return result unless result.nil?
        return default unless default.nil?
        yield long_tag if block_given?
      end

      private

      def machine_client
        provider_client.machine(provider_id)
      end
      memoize :machine_client
    end
  end
end
