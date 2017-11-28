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
      aws_mappings = YAML.load_file(File.expand_path(File.join(__dir__, '../../providers/aws/templates/machine_types.yml'))))
      azure_mappings = YAML.load_file(File.expand_path(File.join(__dir__, '../../providers/azure/templates/machine_types.yml'))))

      self.log_file = config['general']['log_file']

      # Provider: azure
      self.azure_tenant_id = config['provider']['azure']['tenant_id'] || ENV['AZURE_TENANT_ID']
      self.azure_subscription_id = config['provider']['azure']['subscription_id'] || ENV['AZURE_SUBSCRIPTION_ID']
      self.azure_client_id = config['provider']['azure']['client_id'] || ENV['AZURE_TENANT_SECRET']
      self.azure_client_secret = config['provider']['azure']['client_secret'] || ENV['AZURE_CLIENT_SECRET']

      # Provider: aws
      self.aws_access_key_id = config['provider']['aws']['access_key_id'] || ENV['AWS_ACCESS_KEY_ID']
      self.aws_secret_access_key = config['provider']['aws']['secret_access_key'] || ENV['AWS_SECRET_ACCESS_KEY']

      # Azure machine `type` mappings
      self.azure_machine_type_compute_tiny = azure_mappings['compute']['tiny']
      self.azure_machine_type_compute_small = azure_mappings['compute']['small']
      self.azure_machine_type_compute_medium = azure_mappings['compute']['medium']
      self.azure_machine_type_compute_large = azure_mappings['compute']['large']
      self.azure_machine_type_compute_xlarge = azure_mappings['compute']['xlarge']

      self.azure_machine_type_generic_tiny = azure_mappings['generic']['tiny']
      self.azure_machine_type_generic_small = azure_mappings['generic']['small']
      self.azure_machine_type_generic_medium = azure_mappings['generic']['medium']
      self.azure_machine_type_generic_large = azure_mappings['generic']['large']
      self.azure_machine_type_generic_xlarge = azure_mappings['generic']['xlarge']

      self.azure_machine_type_gpu_small = azure_mappings['gpu']['small']
      self.azure_machine_type_gpu_medium = azure_mappings['gpu']['medium']
      self.azure_machine_type_gpu_large = azure_mappings['gpu']['large']

      self.azure_machine_type_memory_tiny = azure_mappings['memory']['tiny']
      self.azure_machine_type_memory_small = azure_mappings['memory']['small']
      self.azure_machine_type_memory_medium = azure_mappings['memory']['medium']
      self.azure_machine_type_memory_large = azure_mappings['memory']['large']
      self.azure_machine_type_memory_xlarge = azure_mappings['memory']['xlarge']
    end
  end
end
