
require 'ipaddr'

module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name, :provider, :region, :networkcidr

      validates_presence_of :name, :region
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
      validate :networkcidr_is_ipv4?

      private

      def cloud
        case provider
        when 'aws'
          Aws2.new
        when 'azure'
          Azure.new
        end
      end

      def networkcidr_is_ipv4?
        valid = begin
                  IPAddr.new(networkcidr).ipv4?
                rescue IPAddr::InvalidAddressError
                  false
                end
        errors.add(:networkcidr, 'Is not a IPv4 address') unless valid
      end
    end
  end
end
