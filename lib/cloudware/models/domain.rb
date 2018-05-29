
# frozen_string_literal: true

require 'ipaddr'

module Cloudware
  module Models
    class Domain < Providers::Base::Application
      ATTRIBUTES = [
        :name, :provider, :region, :networkcidr, :prisubnetcidr, :template,
        :cluster_index, :create_domain_already_exists_flag,
        :network_id, :prisubnet_id, # TODO: Remove the aws specific id's
      ].freeze
      attr_accessor(*ATTRIBUTES)

      validates_presence_of :name, :region
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
      validate :validate_networkcidr_is_ipv4
      validate :validate_prisubnetcidr_is_ipv4
      validate :validate_networkcidr_contains_prisubnetcidr
      validate :validate_domain_does_not_exist_on_create
      before_destroy :validate_cloudware_domain_exists

      private

      def cloud
        Providers.select(provider)::Domain.new(self)
      end

      def run_create
        cloud.create
      end

      def run_destroy
        cloud.destroy
      end

      def validate_cloudware_domain_exists
        return true if Providers.find_domain(provider, region, name)
        errors.add(:domain, 'does not exist')
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

      def validate_domain_does_not_exist_on_create
        return unless create_domain_already_exists_flag
        errors.add(:domain, "error, '#{name}' already exists")
      end
    end
  end
end
