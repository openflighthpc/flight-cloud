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
require 'ostruct'
require 'whirly'
require 'aws-sdk-cloudformation'
require 'aws-sdk-ec2'

Whirly.configure spinner: 'dots2', stop: '[OK]'.green

module Cloudware
  class Config
    attr_accessor :log_file, :azure, :aws, :providers

    def initialize
      config = YAML.load_file(config_path)

      self.log_file = config['general']['log_file'] || log.error('Unable to load log_file')

      # Providers
      self.azure = OpenStruct.new(config['provider']['azure'])
      self.aws = OpenStruct.new(config['provider']['aws'])

      # Providers List (identifying valid/present providers)
      self.providers = []
      config['provider'].each do |a, b|
        providers << a if b.first[1].nil? || !b.first[1].empty?
      end
    end

    def log
      Cloudware.log
    end

    def credentials
      @credentials = OpenStruct.new(
        aws: Aws::Credentials.new(aws.access_key_id, aws.secret_access_key),
      )
    end

    def base_dir
      File.expand_path(File.join(__dir__, '../..'))
    end

    private

    def config_path
      File.expand_path('~/.flightconnector.yml')
    end
  end
end
