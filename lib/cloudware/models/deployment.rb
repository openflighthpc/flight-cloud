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

require 'cloudware/context'
require 'cloudware/models/concerns/provider_client'
require 'cloudware/models/application'
require 'cloudware/models/machine'
require 'pathname'

require 'erb'

module Cloudware
  module Models
    class Deployment < Application
      include Concerns::ProviderClient

      SAVE_ATTR = [
        :template_path, :name, :results, :replacements, :region
      ].freeze
      attr_accessor(*SAVE_ATTR, :context)

      define_model_callbacks :deploy

      before_deploy :validate_template_exists
      before_deploy :validate_replacement_tags
      before_deploy :validate_context
      before_deploy :validate_no_existing_deployment

      def template
        return raw_template unless replacements
        replacements.reduce(raw_template) do |memo, (key, value)|
          memo.gsub("%#{key}%", value.to_s)
        end
      end

      def deploy
        run_callbacks(:deploy) do
          if errors.blank?
            run_deploy
          else
            msg = ERB.new(<<~TEMPLATE, nil, '-').result(binding).chomp
              Failed to deploy resources. The following errors have occurred:
              <% errors.messages.map do |key, messages| -%>
              <% messages.each do |message| -%>
              <%= key %>: <%= message %>
              <% end -%>
              <% end -%>
TEMPLATE
            raise ModelValidationError, msg
          end
        end
      end

      def destroy
        context&.remove_deployment(self)
        provider_client.destroy(tag)
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

      def run_deploy
        self.results = provider_client.deploy(tag, template)
      ensure
        context.with_deployment(self)
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

      def validate_context
        return if context.is_a? Cloudware::Context
        errors.add(:context, 'Is not a context model')
      end

      def validate_no_existing_deployment
        return unless context.respond_to?(:find_deployment)
        return unless context.find_deployment(name)
        errors.add(:context, 'The deployment already exists')
      end
    end
  end
end
