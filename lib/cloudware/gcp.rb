module Cloudware
  module Provider
    class Gcp
      attr_accessor :name
      
      def self.create_domain(name, networkcidr, subnets)
        puts "Cloudware::Provider::Gcp.create_domain"
      end
    end
  end
end
