
RSpec.describe Cloudware::Node, type: :model do
  it { is_expected.to have_many(:outputs) }

  it { is_expected.to validate_presence_of(:name) }
end
