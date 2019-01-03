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

      SAVE_ATTR = [
        :template_path, :name, :results, :replacements, :region, :timestamp,
        :deployment_error
      ].freeze
      attr_accessor(*SAVE_ATTR)

      define_model_callbacks :deploy
      define_model_callbacks :destroy

      before_deploy :validate_template_exists
      before_deploy :validate_replacement_tags
      before_deploy :validate_region
      before_deploy :validate_no_existing_deployment

      before_destroy :validate_existing_deployment

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
          delete if force
          run_destroy
        end
      end

      def machines
        Machine.build_from_context(self)
      end

      def to_h
        SAVE_ATTR.each_with_object({}) do |key, memo|
          memo[key] = send(key)
        end
      end

      private

      def context
        Context.new(region: region)
      end
      memoize :context

      def run_deploy
        self.timestamp = Time.now
        self.results = provider_client.deploy(tag, template)
      rescue => e
        self.deployment_error = e.message
        Log.error(e.message)
        raise DeploymentError, <<~ERROR.chomp
          An error has occured. Please see for further details:
          `#{Config.app_name} list deployments --verbose`
        ERROR
      ensure
        context.save_deployments(self)
      end

      def run_destroy
        begin
          provider_client.destroy(tag)
        rescue => e
          Log.error(e.message)
          raise DeploymentError, <<~ERROR.chomp
            An has error occured when destroying '#{name}'. See logs for full
            details: #{Log.path}
          ERROR
        end
        delete
      end

      def delete
        context.remove_deployments(self)
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

      def validate_template_exists
        return if File.exists?(template_path)
        errors.add(:template, "No such template: #{template_path}")
      end

      def validate_replacement_tags
        return unless File.exists?(template_path)
        template.scan(/%[\w-]*%/).each do |match|
          errors.add(match, 'Was not replaced in the template')
        end
      end

      def validate_region
        return if region
        errors.add(:region, 'No region specified')
      end

      def validate_no_existing_deployment
        # Reload the context during the validation `context(true)`
        return unless context(true).find_deployment(name)
        errors.add(:context, 'The deployment already exists')
      end

      def validate_existing_deployment
        # Reload the context during the validation `context(true)`
        return if context(true).find_deployment(name)
        errors.add(:context, 'The deployment does not exists')
      end
    end
  end
end
