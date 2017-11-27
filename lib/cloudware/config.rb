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

    def initialize(cfg_file)
      config = YAML.load_file(cfg_file)
      self.log_file = config['general']['log_file']

      # Provider: azure
      unless config['provider']['azure'].to_s.empty?
        self.azure_tenant_id = config['provider']['azure']['tenant_id'] unless config['provider']['azure']['tenant_id'].to_s.empty? || ENV['AZURE_TENANT_ID']
        self.azure_subscription_id = config['provider']['azure']['subscription_id'] unless config['provider']['azure']['subscription_id'].to_s.empty? || ENV['AZURE_SUBSCRIPTION_ID']
        self.azure_client_secret = config['provider']['azure']['client_secret'] unless config['provider']['azure']['client_secret'].to_s.empty? || ENV['AZURE_CLIENT_SECRET']
        self.azure_client_id = config['provider']['azure']['client_id'] unless config['provider']['azure']['client_id'].to_s.empty? || ENV['AZURE_CLIENT_ID']
      end

      # Provider: aws
      unless config['provider']['aws'].to_s.empty?
        self.aws_access_key_id = config['provider']['aws']['access_key_id'] unless config['provider']['aws']['access_key_id'].to_s.empty? || ENV['AWS_ACCESS_KEY_ID']
        self.aws_secret_access_key = config['provider']['aws']['secret_access_key'] unless config['provider']['aws']['secret_access_key'].to_s.empty? || ENV['AWS_SECRET_ACCESS_KEY']
      end
    end
  end
end
