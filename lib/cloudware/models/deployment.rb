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

require 'cloudware/context'
require 'cloudware/models/deployment_callbacks'
require 'cloudware/models/concerns/provider_client'
require 'cloudware/models/application'
require 'cloudware/models/machine'
require 'pathname'
require 'time'

require 'erb'

module Cloudware
  module Models
    class Deployment < Application
      include Concerns::ProviderClient
      include DeploymentCallbacks

      include FlightConfig::Updater

      def initialize(cluster, name, **_h)
        self.cluster = cluster
        self.name = name
        super
      end

      SAVE_ATTR = [
        :template_path, :name, :results, :replacements,
        :deployment_error, :cluster, :epoch_time
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

      def results
        __data__.fetch(:results, default: {}).deep_symbolize_keys
      end

      # Ensure the template is a string not `Pathname`
      def template_path=(path)
        __data__.set(:template_path, value: path.to_s)
      end

      def path
        Cluster.load(cluster.to_s).join('var/deployments', name + '.yaml')
      end

      def template
        return raw_template unless replacements
        replacements.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        run_callbacks(:deploy) do
          unless errors.blank?
            raise ModelValidationError, render_errors_message('destroy')
          end
          run_deploy
        end
      end

      def destroy(force: false)
        run_callbacks(:destroy) do
          unless errors.blank?
            raise ModelValidationError, render_errors_message('destroy')
          end
          run_destroy
        end
      end

      def to_h
        SAVE_ATTR.each_with_object({}) do |key, memo|
          memo[key] = send(key)
        end
      end

      def region
        # Protect the load from a `nil` cluster. There is a separate validation
        # for nil clusters
        Cluster.load(cluster.to_s).region
      end

      def <=>(other)
        (epoch_time || 0).<=>(other&.epoch_time || 0)
      end

      def timestamp
        return if epoch_time.nil?
        Time.at(epoch_time)
      end

      private

      def context
        Context.new(cluster: cluster)
      end
      memoize :context

      def run_deploy
        self.epoch_time = Time.now.to_i
        self.results = provider_client.deploy(tag, template)
      rescue => e
        self.deployment_error = e.message
        Log.error(e.message)
      end

      def run_destroy
        begin
          provider_client.destroy(tag)
        rescue => e
          self.deployment_error = e.message
          Log.error(e.message)
          return false
        end
      end

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

      def tag
        "cloudware-deploy-#{name}"
      end

      def raw_template
        File.read(template_path)
      end
    end
  end
end
