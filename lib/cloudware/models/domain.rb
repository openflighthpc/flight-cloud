
require 'ipaddr'

module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name, :provider, :region, :networkcidr, :prisubnetcidr

      validates_presence_of :name, :region
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
      validate :networkcidr_is_ipv4?
      validate :prisubnetcidr_is_ipv4?

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
        validate_ipv4?(:networkcidr)
      end

      def prisubnetcidr_is_ipv4?
        validate_ipv4?(:prisubnetcidr)
      end

      def validate_ipv4?(address_name)
        valid = begin
                  IPAddr.new(send(address_name)).ipv4?
                rescue IPAddr::InvalidAddressError
                  false
                end
        errors.add(address_name, 'Is not a IPv4 address') unless valid
      end
    end
  end
end
