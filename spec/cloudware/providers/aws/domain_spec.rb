
# frozen_string_literal: true

RSpec.describe Cloudware::Providers::AWS::Domain do
  it 'can build a valid domain object' do
    expect(build(:aws_domain)).to be_valid
  end

  describe '#name' do
    it 'can not be nil' do
      expect(build(:aws_domain, name: nil)).not_to be_valid
    end

    it 'errors if it contains special characters' do
      expect(build(:aws_domain, name: '!!')).not_to be_valid
    end
  end

  describe '#region' do
    it 'can not be nil' do
      expect(build(:aws_domain, region: nil)).not_to be_valid
    end
  end

  shared_examples 'valid IPv4' do |address_name|
    it 'must be an IPv4 address' do
      domain = build(:aws_domain, address_name => '10.0.0.257/16')
      expect(domain).not_to be_valid
    end
  end

  describe '#networkcidr' do
    include_examples 'valid IPv4', :networkcidr
  end

  describe '#prisubnetcidr' do
    include_examples 'valid IPv4', :prisubnetcidr

    it 'must be contained within the networkcidr' do
      ip_ranges = {
        networkcidr: '10.0.0.0/16',
        prisubnetcidr: '11.0.1.0/24',
      }
      expect(build(:aws_domain, **ip_ranges)).not_to be_valid
    end
  end
end
