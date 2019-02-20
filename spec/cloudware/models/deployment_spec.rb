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

require 'cloudware/models'
require 'cloudware/providers/base'

RSpec.describe Cloudware::Models::Deployment do
  subject do
    build(:deployment, replacements: replacements).tap do |deployment|
      Cloudware::Models::Cluster.create_or_update(deployment.cluster)
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
