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

require 'cloudware/models'
require 'cloudware/providers/base'

RSpec.describe Cloudware::Models::Deployment do
  subject do
    build(:deployment, replacements: replacements).tap do |deployment|
      Cloudware::Models::Profile.create_or_update(deployment.cluster)
    end
  end

  let(:replacements) { nil }
  let(:double_client) do
    object_double(Cloudware::Providers::Base::Client.new('region'))
  end

  # Mock the provider_client
  before do
    allow(subject).to receive(:provider_client).and_return(double_client)
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

        it 'does not record any deployment errors' do
          subject.deploy
          expect(subject.deployment_error).to be_nil
        end
      end
    end

    describe '#destroy' do
      let(:template_content) { '' }

      before do
        allow(double_client).to receive(:deploy)
        allow(double_client).to receive(:destroy)
      end

      context 'with an existing deployment' do
        before { subject.deploy }

        context 'with an error during the destroy' do
          before do
            allow(double_client).to receive(:destroy).and_raise('Some error')
          end

          it 'does delete the deployment if the force flag is provided' do
            begin subject.destroy(force: true); rescue; end
            deployments = Cloudware::Models::Deployments.read(subject.cluster)
            expect(deployments.find_by_name(subject.name)).to be_nil
          end
        end
      end
    end
  end
end
