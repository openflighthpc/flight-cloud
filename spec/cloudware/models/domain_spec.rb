
RSpec.describe Cloudware::Models::Domain do
  it 'can build a valid domain object' do
    expect(build(:domain)).to be_valid
  end
end
