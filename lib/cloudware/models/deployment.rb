# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
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

require 'cloudware/models/deployment_callbacks'
require 'cloudware/models/concerns/provider_client'
require 'cloudware/models/application'
require 'cloudware/models/machine'
require 'cloudware/root_dir'

require 'pathname'
require 'time'

require 'erb'

module Cloudware
  module Models
    class Deployment
      include ActiveModel::Validations
      include Concerns::ProviderClient
      include DeploymentCallbacks

      include FlightConfig::Updater
      include FlightConfig::Deleter
      include FlightConfig::Globber

      def self.create!(*a, template:, replacements:)
        create(*a) do |dep|
          dep.template_path = template
          dep.replacements = replacements
          dep.validate_or_error('create')
        end
      rescue FlightConfig::CreateError => e
        raise e.exception "Cowardly refusing to recreate '#{name}'"
      end

      def self.deploy!(*a)
        reraise_missing_file do
          update(*a) do |dep|
            dep.validate_or_error('deploy')
            dep.deploy
          end
        end
      end

      def self.delete!(*a)
        reraise_missing_file { delete(*a, &:destroy) }
      end

      private_class_method

      def self.reraise_missing_file
        yield if block_given?
      rescue FlightConfig::MissingFile => e
        raise e.exception "The deployment does not exist"
      end

      attr_reader :cluster, :name

      def initialize(cluster, name, **_h)
        @cluster = cluster
        @name = name
      end

      SAVE_ATTR = [
        :template_path, :results, :replacements,
        :deployment_error, :epoch_time
      ].freeze

      SAVE_ATTR.each do |method|
        define_method(method) { __data__.fetch(method) }
        define_method(:"#{method}=") do |v|
          if v.nil?
            __data__.delete(method)
          else
            __data__.set(method, value: v)
          end
        end
      end

      def cluster_config
        # Protect the read from a `nil` cluster. There is a separate validation
        # for nil clusters
        @cluster_config ||= Models::Cluster.read(cluster.to_s)
      end

      def results
        __data__.fetch(:results, default: {}).deep_symbolize_keys
      end

      # Ensure the template is a string not `Pathname`
      def template_path=(path)
        __data__.set(:template_path, value: path.to_s)
      end

      def path
        RootDir.content_cluster(cluster.to_s, 'var/deployments', name + '.yaml')
      end

      def template
        return raw_template unless replacements
        replacements.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        self.epoch_time = Time.now.to_i
        self.results = provider_client.deploy(tag, template)
      rescue => e
        self.deployment_error = e.message
        Log.error(e.message)
      rescue Interrupt
        self.deployment_error = 'Received Interrupt!'
        Log.error "Received SIGINT whilst deploying: #{name}"
      end

      def destroy(force: false)
        provider_client.destroy(tag)
        true
      rescue => e
        self.deployment_error = e.message
        Log.error(e.message)
        return false
      end

      def to_h
        SAVE_ATTR.each_with_object({}) do |key, memo|
          memo[key] = send(key)
        end
      end

      def region
        cluster_config.region
      end

      def <=>(other)
        (epoch_time || 0).<=>(other&.epoch_time || 0)
      end

      def timestamp
        return if epoch_time.nil?
        Time.at(epoch_time)
      end

      def tag
        "#{Config.prefix_tag}-#{name}-#{cluster_config.tag}"
      end

      def validate_or_error(action)
        validate
        unless errors.blank?
          raise ModelValidationError, render_errors_message(action)
        end
      end

      private

      def render_errors_message(action)
        ERB.new(<<~TEMPLATE, nil, '-').result(binding).chomp
          Failed to <%= action %> resources. The following errors have occurred:
          <% errors.messages.map do |key, messages| -%>
          <% messages.each do |message| -%>
          <%= key %>: <%= message %>
          <% end -%>
          <% end -%>
        TEMPLATE
      end

      def raw_template
        File.read(template_path)
      end
    end
  end
end
