# frozen_string_literal: true

RSpec.describe Cloudware::Models::Machine do
  let(:machine_name) { 'test' }
  subject { described_class.new(name: machine_name, deployment: deployment) }

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
        [Cloudware::Models::Machine.tag_generator(machine_name, key), value]
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
