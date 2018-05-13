
require 'ipaddr'

module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name, :provider, :region, :networkcidr, :prisubnetcidr

      validates_presence_of :name, :region
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
      validate :validate_networkcidr_is_ipv4
      validate :validate_prisubnetcidr_is_ipv4
      validate :validate_networkcidr_contains_prisubnetcidr

      # TODO: Integrate this into a before_create hook
      def exists?
        Cloudware::Domains.list.include? name || false
      end

      private

      def cloud
        case provider
        when 'aws'
          Aws2.new
        when 'azure'
          Azure.new
        end
      end

      def run_create(*_a)
        cloud.create_domain(name, SecureRandom.uuid, networkcidr,
                            prisubnetcidr, region)
      end

      def validate_networkcidr_is_ipv4
        validate_ipv4(:networkcidr)
      end

      def validate_prisubnetcidr_is_ipv4
        validate_ipv4(:prisubnetcidr)
      end

      def validate_ipv4(address_name)
        return true if begin
                         IPAddr.new(send(address_name)).ipv4?
                       rescue IPAddr::Error
                         false
                       end
        errors.add(address_name, 'Is not a IPv4 address')
        false
      end

      def validate_networkcidr_contains_prisubnetcidr
        return unless validate_networkcidr_is_ipv4
        return unless validate_prisubnetcidr_is_ipv4
        network = IPAddr.new(networkcidr)
        pri = IPAddr.new(prisubnetcidr)
        return true if network.include?(pri)
        errors.add(:prisubnetcidr,
                   'Prisubnetcidr is not within the network')
        false
      end
    end
  end
end
