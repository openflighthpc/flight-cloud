# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You hould have received a copy of the GNU General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
#==============================================================================
require 'yaml'

module Cloudware
  class Config
    attr_accessor :log_file
    attr_accessor :azure_tenant_id, :azure_subscription_id, :azure_client_secret, :azure_client_id
    attr_accessor :aws_access_key_id, :aws_secret_access_key
    attr_accessor :providers

    def initialize
      config = YAML.load_file(config_path) || raise("Couldn't load config file #{cfg_file}")

      self.log_file = config['general']['log_file'] || log.error('Unable to load log_file')

      # Provider: azure
      self.azure_tenant_id = begin
                               config['provider']['azure']['tenant_id']
                             rescue StandardError
                               nil
                             end
      self.azure_subscription_id = begin
                                     config['provider']['azure']['subscription_id']
                                   rescue StandardError
                                     nil
                                   end
      self.azure_client_id = begin
                               config['provider']['azure']['client_id']
                             rescue StandardError
                               nil
                             end
      self.azure_client_secret = begin
                                   config['provider']['azure']['client_secret']
                                 rescue StandardError
                                   nil
                                 end

      # Provider: aws
      self.aws_access_key_id = begin
                                 config['provider']['aws']['access_key_id']
                               rescue StandardError
                                 nil
                               end
      self.aws_secret_access_key = begin
                                     config['provider']['aws']['secret_access_key']
                                   rescue StandardError
                                     nil
                                   end

      # Providers List (identifying valid/present providers)
      self.providers = []
      config['provider'].each do |a, b|
        providers << a if b.first[1].nil? || !b.first[1].empty?
      end
    end

    def log
      Cloudware.log
    end

    private

    def config_path
      File.expand_path('~/.flightconnector.yml')
    end
  end
end
