# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

module Cloudware
  class AccumulatedErrors < Array
    def enumerate(enum)
      enum.each do |*a|
        begin
          yield(*a) if block_given?
        rescue => e
          Log.error_puts('An error has occurred!')
          self << e
        end
      end
    end

    def catch
      yield
    rescue => e
      self << e
    end

    def raise_if_any
      if empty?
        true
      elsif length == 1
        raise first
      else
        raise Cloudware::AccumulatedError, <<~ERROR
          The following errors have occurred:
          #{self.map(&:message).join("\n\n")}
        ERROR
      end
    end
  end

  # Base errors for all further errors to inherit from
  class CloudwareError < RuntimeError; end
  class UserError < CloudwareError; end
  class InternalError < CloudwareError; end
  class ProviderError < CloudwareError; end
  class AccumulatedError < CloudwareError; end

  # Other errors
  class ConfigError < CloudwareError; end
  class InvalidInput < UserError; end
  class ModelValidationError < UserError; end
  class InvalidAzureRequest < UserError; end
  class DeploymentError < UserError; end
end
