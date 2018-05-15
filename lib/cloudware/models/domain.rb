
require 'ipaddr'

module Cloudware
  module Models
    class Domain < Application
      ATTRIBUTES = [
        :name, :provider, :region, :networkcidr, :prisubnetcidr, :template
      ]
      attr_accessor(*ATTRIBUTES)

      validates_presence_of :name, :region
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
      validate :validate_networkcidr_is_ipv4
      validate :validate_prisubnetcidr_is_ipv4
      validate :validate_networkcidr_contains_prisubnetcidr

      before_create :validate_domain_name_is_unique

      private

      def run_create
        case provider
        when 'aws'
          Providers::Domains::AWS.new(self)
        when 'azure'
          raise NotImplementedError
        end.create
      end

      def validate_networkcidr_is_ipv4(**h)
        validate_ipv4(:networkcidr, **h)
      end

      def validate_prisubnetcidr_is_ipv4(**h)
        validate_ipv4(:prisubnetcidr, **h)
      end

      def validate_ipv4(address_name, add_error: true)
        return true if begin
                         IPAddr.new(send(address_name)).ipv4?
                       rescue IPAddr::Error
                         false
                       end
        errors.add(address_name, 'Is not a IPv4 address') if add_error
        false
      end

      def validate_networkcidr_contains_prisubnetcidr
        return unless validate_networkcidr_is_ipv4(add_error: false)
        return unless validate_prisubnetcidr_is_ipv4(add_error: false)
        network = IPAddr.new(networkcidr)
        pri = IPAddr.new(prisubnetcidr)
        return true if network.include?(pri)
        errors.add(:prisubnetcidr,
                   'Prisubnetcidr is not within the network')
        false
      end

      def validate_domain_name_is_unique
        return unless Cloudware::Domains.list.include?(name)
        errors.add(:name, "the '#{name}' domain already exists")
      end
    end
  end
end

