
RSpec.describe Cloudware::Output, type: :model do
  it { is_expected.to belong_to(:deployment) }
  it { is_expected.to belong_to(:node).optional }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:value) }
end
