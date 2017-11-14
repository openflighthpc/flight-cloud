
require 'google/cloud/resource_manager'

module Cloudware
  module Provider
    class Gcp
      attr_accessor :name

      def initialize
        client
      end

      def client
        @resource_manager = Google::Cloud::ResourceManager.new
      end

      def list_domains
        domains = @resource_manager.projects
        projects.each do |project|
          puts project.project_id
        end
      end
      
      def create_domain(name, networkcidr, subnets)
        domain = @resource_manager.create_project name,
                                        name: name,
                                        labels: {
                                          cloudware_domain: name,
                                          network_cidr: networkcidr
                                        }
      end

      def destroy_domain(name)
        puts "==> Destroying domain #{name}. This may take a while..."
        @resource_manager.delete name
      end
    end
  end
end
