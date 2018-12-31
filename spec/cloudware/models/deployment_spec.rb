# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

require 'cloudware/providers/base'

RSpec.describe Cloudware::Models::Deployment do
  shared_examples 'deploy raises ModelValidationError' do
    it 'raises ModelValidationError' do
      expect do
        subject.deploy
      end.to raise_error(Cloudware::ModelValidationError)
    end
  end

  shared_examples 'validation error deployment' do
    include_examples 'deploy raises ModelValidationError'

    it 'does not save to the context' do
      begin subject.deploy; rescue RuntimeError; end
      expect(context.deployments).not_to include(subject)
    end
  end

  shared_examples 'validated deployment' do
    it 'does not error' do
      expect do
        subject.deploy
      end.not_to raise_error StandardError
    end
  end

  subject do
    build(:deployment, replacements: replacements, context: context)
  end

  let(:replacements) { nil }
  let(:context) { build(:context) }
  let(:double_client) do
    object_double(Cloudware::Providers::Base::Client.new('region'))
  end

  # Mock the provider_client
  before do
    allow(subject).to receive(:provider_client).and_return(double_client)
  end

  it 'does not update the context on build' do
    deployment = build(:deployment, context: context)
    expect(context.deployments).not_to include(deployment)
  end

  context 'with a replacement hash' do
    let(:replacements) { { replace_key1: 'value1', replace_key2: 'value2' } }
    let(:raw_template) do
      <<-TEMPLATE.strip_heredoc
        key1: '%replace_key1%'
        key2: '%replace_key2%'
      TEMPLATE
    end

    before do
      allow(subject).to receive(:raw_template).and_return(raw_template)
    end

    it 'renders the template with the replaced keys' do
      template = Cloudware::Data.load_string(subject.template)
      expect(template[:key1]).to eq(replacements[:replace_key1])
      expect(template[:key2]).to eq(replacements[:replace_key2])
    end
  end

  context 'with machine ids' do
    let(:machines) { ['node1', 'node2'] }
    let(:results) do
      machines.each_with_object({}) do |name, memo|
        tag_suffix = Cloudware::Models::Machine::PROVIDER_ID_FLAG
        tag = Cloudware::Models::Machine.tag_generator(name, tag_suffix)
        memo[tag] = "#{name}-id"
      end
    end

    before { allow(subject).to receive(:results).and_return(results) }

    describe '#machines' do
      it 'returns objects with the machine names' do
        expect(subject.machines.map(&:name)).to contain_exactly(*machines)
      end

      xit 'creates objects that back reference the deployment' do
        machine_deployments = subject.machines.map(&:deployment)
        expect(machine_deployments.uniq).to contain_exactly(subject)
      end
    end
  end

  context 'without a template' do
    describe '#deploy' do
      include_examples 'deploy raises ModelValidationError'
    end
  end

  context 'with an existing template' do
    before do
      path = subject.send(:template_path)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, template_content)
    end

    describe '#deploy' do
      before { allow(double_client).to receive(:deploy) }

      context 'with a blank template' do
        let(:template_content) { '' }

        it 'passes' do
          expect { subject.deploy }.not_to raise_error
        end

        it_behaves_like 'validated deployment'

        it 'does not record any deployment errors' do
          subject.deploy
          expect(subject.deployment_error).to be_nil
        end

        context 'without a context' do
          let(:context) { nil }

          include_examples 'deploy raises ModelValidationError'
        end

        context 'with an existing deployment' do
          let(:existing_deployment) do
            build(:deployment, name: subject.name)
          end

          before { context.with_deployment(existing_deployment) }

          it_behaves_like 'validation error deployment'
        end

        context 'with a provider related error' do
          let(:message) { 'I am an error message' }

          before do
            allow(double_client).to receive(:deploy).and_raise(RuntimeError, message)
          end

          it_behaves_like 'validated deployment'

          it 'saves the deployment error message' do
            subject.deploy
            expect(subject.deployment_error).to eq(message)
          end
        end
      end

      context 'with a replacement tag' do
        let(:template_content) { '%unreplaced-tag%' }

        it_behaves_like 'validation error deployment'
      end
    end
  end
end
