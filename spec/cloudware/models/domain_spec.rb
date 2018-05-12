
RSpec.describe Cloudware::Models::Domain do
  it 'can build a valid domain object' do
    expect(build(:domain)).to be_valid
  end

  describe '#name' do
    it 'can not be nil' do
      expect(build(:domain, name: nil)).not_to be_valid
    end
  end

  describe '#provider' do
    it 'must be a supported provider' do
      expect(build(:domain, provider: 'missing')).not_to be_valid
    end
  end
end
