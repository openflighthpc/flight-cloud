
RSpec.describe Cloudware::Deployment, type: :model do
  it { is_expected.to have_many(:outputs) }
  it { is_expected.to have_many(:nodes).through(:outputs) }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:template) }
  it { is_expected.to validate_presence_of(:platform) }
  it do
    is_expected.to validate_inclusion_of(:platform).in_array ['aws', 'azure']
  end
end
