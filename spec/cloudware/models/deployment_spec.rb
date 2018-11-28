# frozen_string_literal: true

RSpec.describe Cloudware::Models::Deployment do
  let(:replacements) { nil }
  subject { build(:deployment, replacements: replacements) }

  context 'with a replacement hash' do
    let(:replacements) { { replace_key1: 'value1', replace_key2: 'value2' } }
    let(:raw_template) {
      <<-TEMPLATE.strip_heredoc
        key1: '%replace_key1%'
        key2: '%replace_key2%'
      TEMPLATE
    }

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
      prefix = Cloudware::Models::Machine::TAG_PREFIX
      machines.each_with_object({}) do |name, memo|
        memo[:"#{prefix}#{name}TAGid"] = "#{name}-id"
      end
    end

    before { allow(subject).to receive(:results).and_return(results) }

    describe '#machines' do
      it 'returns objects with the machine names' do
        expect(subject.machines.map(&:name)).to contain_exactly(*machines)
      end

      it 'creates objects that back reference the deployment' do
        machine_deployments = subject.machines.map(&:deployment)
        expect(machine_deployments.uniq).to contain_exactly(subject)
      end
    end
  end

  context 'with a deployment context' do
    let(:context) { build(:context) }

    it 'is automatically added to the context' do
      deployment = build(:deployment, context: context)
      find_deployment = context.deployments.find { |d| d.name == deployment.name }
      expect(find_deployment).to eq(deployment)
    end
  end
end
