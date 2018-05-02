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

    def initialize(cfg_file)
      config = YAML.load_file(cfg_file) || raise("Couldn't load config file #{cfg_file}")

      self.log_file = config['general']['log_file'] || log.error('Unable to load log_file')

      # Provider: azure
      self.azure_tenant_id = config['provider']['azure']['tenant_id'] rescue nil
      self.azure_subscription_id = config['provider']['azure']['subscription_id'] rescue nil
      self.azure_client_id = config['provider']['azure']['client_id'] rescue nil
      self.azure_client_secret = config['provider']['azure']['client_secret'] rescue nil

      # Provider: aws
      self.aws_access_key_id = config['provider']['aws']['access_key_id'] rescue nil
      self.aws_secret_access_key = config['provider']['aws']['secret_access_key'] rescue nil

      # Providers List (identifying valid/present providers)
      self.providers = []
      config['provider'].each do |a, b|
        if b.first[1].nil? || ! b.first[1].empty?
          self.providers << a
        end
      end
    end

    def log
      Cloudware.log
    end
  end
end
