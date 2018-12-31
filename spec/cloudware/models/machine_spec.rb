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

RSpec.describe Cloudware::Models::Machine do
  subject { described_class.new(name: machine_name, context: context) }

  let(:machine_name) { 'test' }
  let(:context) do
    build(:context).tap { |c| c.save_deployments(deployment) }
  end

  context 'with a blank deployment' do
    let(:deployment) { build(:deployment) }

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
    let(:deployment) { build(:deployment, results: deployment_results) }

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
