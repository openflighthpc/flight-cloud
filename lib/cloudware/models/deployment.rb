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
      include FlightConfig::Links

      # Hack the links mechanism to work with inheritance, consider refactoring
      def self.links_class
        @links_class ||= if self == Deployment
          super
        else
          superclass.links_class.dup
        end
      end

      define_link(:cluster, Models::Cluster) { [cluster] }

      # TODO: Make this an archatype class and replace the path with:
      # raise NotImplementedError
      def self.path(cluster, name)
        RootDir.content_cluster(cluster.to_s, 'var/deployments', name + '.yaml')
      end

      def self.read!(*a)
        reraise_missing_file { read(*a) }
      end

      def self.create!(*a, template:)
        create(*a) do |dep|
          src = Pathname.new(template)
          raise ConfigError, <<~ERROR.chomp unless src.absolute?
            The source template must be an absolute path
          ERROR
          raise ConfigError, <<~ERROR.chomp unless src.file?
            The source template must exist and be a regular file:
            #{src.to_s}
          ERROR
          FileUtils.mkdir_p File.dirname(dep.template_path)
          FileUtils.cp src, dep.template_path
        end
      rescue FlightConfig::CreateError => e
        raise e.exception, <<~ERROR.chomp
          Can not re-create an existing deployment
        ERROR
      end

      def self.deploy!(*a)
        reraise_missing_file do
          update(*a) do |dep|
            dep.validate_or_error('deploy')
            dep.deploy
          end
        end
      end

      def self.destroy!(*a)
        reraise_missing_file { update(*a, &:destroy) }
      end

      def self.delete!(*a)
        reraise_missing_file do
          delete(*a) do |dep|
            next true unless dep.deployed
            raise DeploymentError, <<~ERROR.chomp
              Can not delete a currently running deployment
            ERROR
          end
        end
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
        super
      end

      # TODO: Remove template_path as a saved parameter and make it static
      # Soon all deployments will have a 1:1 relationship with its template
      # Replace the archetype method with: raise NotImplementedError
      SAVE_ATTR = [
        :template_path, :results, :replacements, :deployed,
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

      def provider
        links.cluster.provider
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

      def template
        return raw_template unless replacements
        dep = ReplacementFactory.new(cluster, self.name)
        replacements.reduce(raw_template) do |memo, (key, value)|
          # Resolve domain(s) of key value pairs if necessary
          value = dep.parse_key_pair(key.to_sym, value) if value.include? "*"

          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        self.deployed = true
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
        __data__.delete("deployment_error") if self.deployment_error
        self.deployed = false
        true
      rescue => e
        self.deployment_error = e.message
        Log.error(e.message)
        return false
      rescue Interrupt
        self.deployment_error = 'Received Interrupt!'
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
        error(action) unless errors.blank?
      end

      def error(action)
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
