# frozen_string_literal: true

module Cloudware
  module Models
    class Domain < Application
      include Concerns::DeploymentTags
      TAG_TYPE = 'DOMAIN'
    end
  end
end
