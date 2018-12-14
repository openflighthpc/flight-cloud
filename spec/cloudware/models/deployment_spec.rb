# frozen_string_literal: true

require 'providers/base'

RSpec.describe Cloudware::Models::Deployment do
  let(:replacements) { nil }
  let(:context) { build(:context) }
  let(:double_client) do
    object_double(Cloudware::Providers::Base::Client.new('region'))
  end

  subject do
    build(:deployment, replacements: replacements, context: context)
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
      end

      context 'with a replacement tag' do
        let(:template_content) { '%unreplaced-tag%' }

        it 'errors' do
          expect do
            subject.deploy
          end.to raise_error(Cloudware::ModelValidationError)
        end
      end
    end
  end
end
