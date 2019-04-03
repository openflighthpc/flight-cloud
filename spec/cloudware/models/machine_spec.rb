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

RSpec.describe Cloudware::Models::Machine do
  subject { described_class.new(name: machine_name, cluster: deployment.cluster) }

  let(:machine_name) { 'test' }

  context 'with a blank deployment' do
    let!(:deployment) do
      build(:deployment).tap do |d|
        FlightConfig::Core.write(d)
        Cloudware::Models::Cluster.create(d.cluster)
      end
    end

    describe '#provider_id' do
      it 'errors' do
        expect do
          subject.provider_id
        end.to raise_error(Cloudware::ModelValidationError)
      end
    end

    describe '#groups' do
      it 'resturns an empty array' do
        expect(subject.groups).to eq([])
      end
    end
  end

  context 'with a machine results within the deployment' do
    let(:group_names) { ['group1', 'group2'] }
    let(:id) { 'I am the provider id' }
    let(:machine_tags) do
      { key1: 'value1', ID: id, groups: group_names.join(',') }
    end
    let(:machine_name) { 'test-machine' }
    let(:deployment_results) do
      machine_tags.map do |key, value|
        [described_class.tag_generator(machine_name, key), value]
      end.to_h.merge(random_other_key: 'value')
    end
    let(:deployment) do
      build(:deployment, results: deployment_results).tap do |d|
        FlightConfig::Core.write(d)
        Cloudware::Models::Cluster.create(d.cluster)
      end
    end

    describe('#tags') do
      it 'returns the machine results without the tag prefix' do
        expect(subject.tags).to eq(machine_tags)
      end
    end

    describe('#groups') do
      it 'returns the list of groups' do
        expect(subject.groups).to contain_exactly(*group_names)
      end
    end

    describe '#provider_id' do
      it 'returns the id' do
        expect(subject.provider_id).to eq(id)
      end
    end
  end
end
