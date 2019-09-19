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

require 'commander'

module Cloudware
  module CommanderProxyDelegates
    extend ActiveSupport::Concern

    class RunnerProxy
      PROXY_METHODS = [
        :add_command, :command, :program, :global_option, :alias_command, :default_command
      ]

      PROXY_METHODS.each do |method|
        define_method(method) do |*a, &b|
          proxy_calls << [method, a, b]
        end
      end

      def proxy_calls
        @proxy_calls ||= []
      end

      def run(args, prefix: nil)
        runner = ::Commander::Runner.new(args)
        proxy_calls.each_with_object(runner) do |(s, a, b), run|
          run.send(s, *a, &b)
        end
        if prefix
          suffix = runner.program(:name)
          runner.program(:name, "#{prefix} #{suffix}")
        end
        runner.require_program(:version, :description)
        runner.global_option('-h', '--help', 'Display the help text') do
          runner_args = runner.instance_variable_get(:@args) - ['-h', '--help']
          runner.command(:help).run(*runner_args)
          return
        end
        runner.global_option('--version', 'Display version information') do
          say version
          return
        end
        trace = false
        runner.global_option('--trace', 'Display backtrace when an error occurrs') do
          trace = true
        end
        runner.parse_global_options
        runner.remove_global_options runner.options, runner.instance_variable_get(:@args)
        if trace
          runner.run_active_command
        else
          begin
            runner.run_active_command
          rescue => e
            ::Commander::Runner::DEFAULT_ERROR_HANDLER.call(runner, e)
          end
        end
      end
    end

    included do
      class << self
        delegate(*RunnerProxy::PROXY_METHODS, to: :runner_proxy_instance)
      end
    end

    class_methods do
      def runner_proxy_instance
        @runner_proxy_instance ||= RunnerProxy.new
      end

      def run(args)
        args.push('--help') if args.empty?
        Log.info "Run (CLI): #{args.join(' ')}"
        runner_proxy_instance.run(args)
      end
    end
  end
end