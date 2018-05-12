
RSpec.describe Cloudware::Models::Domain do
  it 'can build a valid domain object' do
    expect(build(:domain)).to be_valid
  end

  it 'requires the name field' do
    expect(build(:domain, name: nil)).not_to be_valid
  end
end
