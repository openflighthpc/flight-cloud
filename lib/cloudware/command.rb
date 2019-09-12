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

require 'cloudware/spinner'
require 'cloudware/log'
require 'cloudware/command_config'
require 'memoist'
require 'hashie'

module Cloudware
  class CommanderProxy < Hashie::Dash
    property :klass, required: :true
    property :level, required: true
    property :named, required: true
    property :method, required: false
    property :index, required: false

    def to_lambda
      lambda { |a, o| run_proxy(a, o) }
    end

    private

    def run_proxy(commander_args, commander_opts)
      name, args = if named
                     [commander_args.first, commander_args[1..-1]]
                   else
                     [nil, commander_args]
                   end
      opts = commander_opts.__hash__.dup.tap { |h| h.delete(:trace) }
      primary = opts.delete(:primary)
      instance = klass.new(level, name, index, primary)
      if opts.empty?
        instance.public_send(resolved_method, *args)
      else
        instance.public_send(resolved_method, *args, **opts)
      end
    rescue Interrupt
      $stderr.puts 'Received Interrupt!'
      Log.warn 'Received Interrupt!'
    rescue => e
      Log.fatal(e)
      raise e
    end

    def resolved_method
      method || index || level
    end
  end

  ScopedCommand = Struct.new(:level, :name, :index, :primary) do
    def self.proxy(**kwargs)
      CommanderProxy.new(**kwargs.merge(klass: self)).to_lambda
    end


    def accumulate_errors(*a, &b)
      AccumulatedErrors.new
                       .tap{ |e| e.enumerate(*a, &b) }
                       .raise_if_any
    end

    def config
      @config ||= CommandConfig.read
    end

    def model_klass
      case level
      when :cluster
        require 'cloudware/models/cluster'
        Models::Cluster
      when :domain
        require 'cloudware/models/domain'
        Models::Domain
      when :group, :stack
        require 'cloudware/models/group'
        Models::Group
      when :node
        require 'cloudware/models/node'
        Models::Node
      else
        raise InternalError, "Could not resolve the command level: #{level}"
      end
    end

    def name_or_error
      if name
        name
      elsif [:domain, :cluster].include?(level)
        config.current_cluster
      else
        raise InternalError, 'Failed to run the command as the model name is missing'
      end
    end

    def read_model
      if [:cluster, :domain].include?(level)
        model_klass.read(name_or_error)
      else
        model_klass.read(config.current_cluster, name_or_error)
      end
    end

    def read_cluster
      if level == :cluster
        read_model
      else
        Models::Cluster.read(config.current_cluster)
      end
    end

    def read_node
      Models::Node.read(config.current_cluster, name_or_error)
    end

    def read_group
      Models::Group.read(config.current_cluster, name_or_error)
    end

    def read_deployable
      if [:domain, :stack, :node].include?(level)
        read_model
      else
        raise InternalError, "The #{level} is not a deployable model"
      end
    end

    def read_nodes
      if level == :node
        [read_model]
      elsif level == :group && primary
        read_model.primary_nodes
      elsif level == :domain
        raise InternalError, 'Can not load nodes within the domain scope'
      else
        read_model.read_nodes
      end
    end

    def load_existing_nodes(raw_names)
      names = raw_names.reject do |cur_name|
        next if Models::Node.exists?(config.current_cluster, cur_name)
        Log.warn_puts "Skipping node '#{cur_name}' as it does not exist"
        true
      end
      names.map { |n| Models::Node.read(config.current_cluster, n) }
    end
  end

  class Command
    extend Memoist
    include WithSpinner

    # Override this method to delay requiring libraries until the command is
    # called. Remember to `super`
    def self.delayed_require
      require 'cloudware/models'
    end

    attr_reader :__config__

    def initialize(__config__ = nil)
      self.class.delayed_require
      @__config__ = __config__ || CommandConfig.read
    end

    def run!(*argv, **options)
      class << self
        attr_reader :argv, :options
      end
      @argv = argv.freeze
      @options = OpenStruct.new(options)
      run
    end

    def run
      raise NotImplementedError
    end

    def region
      __config__.region
    end

    private

    def _render(template)
      ERB.new(template, nil, '-').result(binding)
    end
  end
end
