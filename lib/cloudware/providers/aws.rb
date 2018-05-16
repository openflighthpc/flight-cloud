
# frozen_string_literal: true

module Cloudware
  module Providers
    module AWS
      class << self
        # A region is required for finding the regions, hence why it has
        # been hard-coded in this case
        def regions
          @regions ||= Aws::EC2::Client.new(
            credentials: Cloudware.config.credentials.aws,
            region: 'us-east-1'
          ).describe_regions.regions.map(&:region_name)
        end
      end
    end
  end
end
