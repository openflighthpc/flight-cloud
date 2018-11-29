# frozen_string_literal: true

module Cloudware
  module Models
    class Domain < Application
      include Concerns::Tags
      TAG_TYPE = 'DOMAIN'

      attr_accessor :name, :deployment
    end
  end
end
