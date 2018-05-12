
module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name, :provider

      validates_presence_of :name
      validates :provider, inclusion: { in: Cloudware.config.providers }
    end
  end
end
