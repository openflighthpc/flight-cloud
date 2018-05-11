# frozen_string_literal: true

module Cloudware
  # Base errors for all further errors to inherit from
  class CloudwareError < RuntimeError; end
  class UserError < CloudwareError; end
  class InternalError < CloudwareError; end

  # Other errors
  class ConfigError < CloudwareError; end
  class InvalidInput < CloudwareError; end
end
