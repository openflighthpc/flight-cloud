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
require 'aws-sdk-cloudformation'
require 'aws-sdk-ec2'
require 'cloudware/provider/aws/deployment'
require 'cloudware/provider/aws/domain'
require 'cloudware/provider/aws/machine'

EC2 = Aws::EC2
CloudFormation = Aws::CloudFormation
Credentials = Aws::Credentials

module Cloudware
  class Aws
    include Utils
    include Deployment
    include Domain
    include Machine

    def initialize(options = {})
      @options = options
      @region = options[:region] || 'eu-west-1'
    end

    private

    def credentials
      @credentials ||= Credentials.new(
        config.aws_access_key_id,
        config.aws_secret_access_key
      )
    end

    def cfn
      @cfn ||= CloudFormation::Client.new(region: @region, credentials: credentials)
    end

    def ec2(region = @options[:region] || 'eu-west-1')
      @ec2 ||= EC2::Client.new(region: region, credentials: credentials)
    end

    def regions
      @regions ||= begin
        @regions = []
        ec2.describe_regions.regions.each do |region|
          @regions.push(region.region_name)
        end
        @regions
      end
    end

    def search
      @search ||= {}
    end
  end
end
