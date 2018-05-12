
module Cloudware
  module Models
    class Domain < Application
      attr_accessor :name, :provider

      validates_presence_of :name
      validates :name, format: { with: /\A[a-zA-Z0-9-]*\z/ }
      validates :provider, inclusion: { in: Cloudware.config.providers }
    end
  end
end
