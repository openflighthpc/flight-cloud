require 'cloudware/domain'
require 'cloudware/azure'
describe Cloudware::Domain do
  before do
    @name = 'cloudwaretest'
    @provider = 'azure'
    @region = 'uksouth'
    @networkcidr = '10.0.0.0/16'
    @prvsubnetcidr = '10.0.1.0/24'
    @mgtsubnetcidr = '10.0.2.0/24'
    @domain = Cloudware::Domain.new
  end

  it 'should error when an incorrect name is given' do
    @domain.name = 'invalid-name'
    expect(@domain.name).to eq(false)
  end

  it 'returns the correct name' do
    @domain.name = @name
    expect(@domain.name).to eq(@name)
  end

  it 'should error when an incorrect provider is given' do
    @domain.provider = 'alces1234'
    expect(@domain.provider).to eq(false)
  end

  it 'returns the correct provider' do
    @domain.provider = @provider
    expect(@domain.provider).to eq(@provider)
  end

  it 'returns the correct region' do
    @domain.region = @region
    expect(@domain.region).to eq(@region)
  end

  it 'returns the correct network cidr' do
    @domain.networkcidr = @networkcidr
    expect(@domain.networkcidr).to eq(@networkcidr)
  end

  it 'returns the correct prv subnet cidr' do
    @domain.prvsubnetcidr = @prvsubnetcidr
    expect(@domain.prvsubnetcidr).to eq(@prvsubnetcidr)
  end

  it 'returns the correct mgt subnet cidr' do
    @domain.mgtsubnetcidr = @mgtsubnetcidr
    expect(@domain.mgtsubnetcidr).to eq(@mgtsubnetcidr)
  end
end
