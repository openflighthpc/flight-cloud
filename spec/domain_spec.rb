require 'cloudware/domain'
require 'cloudware/azure'
require 'cloudware/aws'
describe Cloudware::Domain do
  context 'with provider azure' do
    before do
      @domain = Cloudware::Domain.new
      @domain.provider = 'azure'
    end

    it 'returns correct provider' do
      expect(@domain.provider).to eq('azure')
    end

    it 'returns the correct name' do
      @domain.name = 'cloudware-test'
      expect(@domain.name).to eq('cloudware-test')
    end

    it 'returns the correct region' do
      @domain.region = 'uksouth'
      expect(@domain.region).to eq('uksouth')
    end

    it 'returns the correct network cidr' do
      @domain.networkcidr = '10.0.0.0/16'
      expect(@domain.networkcidr).to eq('10.0.0.0/16')
    end

    it 'returns the correct prv subnet cidr' do
      @domain.prvsubnetcidr = '10.0.1.0/24'
      expect(@domain.prvsubnetcidr).to eq('10.0.1.0/24')
    end

    it 'returns the correct mgt subnet cidr' do
      @domain.prvsubnetcidr = '10.0.2.0/24'
      expect(@domain.prvsubnetcidr).to eq('10.0.2.0/24')
    end

    it 'should not return a provider' do
      expect(@domain.get_item('provider').to be(nil)
    end
  end
end
