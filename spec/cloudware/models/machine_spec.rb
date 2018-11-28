# frozen_string_literal: true

RSpec.describe Cloudware::Models::Machine do
  context 'with a blank deployment' do
    let(:deployment) { build(:deployment) }
    subject { described_class.new(name: 'test', deployment: deployment) }

    describe '#provider_id' do
      it 'errors' do
        expect do
          subject.provider_id
        end.to raise_error(Cloudware::ModelValidationError)
      end
    end
  end
end
