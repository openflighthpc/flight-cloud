require 'cloudware/domain'
require 'cloudware/azure'
require 'cloudware/aws'
require 'cloudware/config'
require 'cloudware/log'
require 'cloudware'
require 'haikunator'

describe Cloudware::Domain do
  context 'with provider azure' do
    before do
      @name = 'cloudware-azure-test'
      @provider = 'azure'
      @region = 'uksouth'
      @networkcidr = '10.0.0.0/16'
      @prvsubnetcidr = '10.0.1.0/24'
      @mgtsubnetcidr = '10.0.2.0/24'
      @domain = Cloudware::Domain.new
      @domain.name = @name
      @domain.provider = @provider
    end

    it 'returns correct provider' do
      expect(@domain.provider).to eq(@provider)
    end

    it 'returns the correct name' do
      expect(@domain.name).to eq(@name)
    end

    it 'returns the correct region' do
      @domain.region = 'uksouth'
      expect(@domain.region).to eq(@region)
    end

    it 'returns the correct network cidr' do
      @domain.networkcidr = @networkcidr
      expect(@domain.networkcidr).to eq(@networkcidr)
    end

    it 'validates the network cidr' do
      expect(@domain.valid_cidr?(@networkcidr)).to be(true)
    end

    it 'returns the correct prv subnet cidr' do
      @domain.prvsubnetcidr = @prvsubnetcidr
      expect(@domain.prvsubnetcidr).to eq(@prvsubnetcidr)
    end

    it 'validates the prv/mgt subnet cidrs' do
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @prvsubnetcidr)).to be(true)
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @mgtsubnetcidr)).to be(true)
    end

    it 'returns the correct mgt subnet cidr' do
      @domain.mgtsubnetcidr = @mgtsubnetcidr
      expect(@domain.mgtsubnetcidr).to eq(@mgtsubnetcidr)
    end

    it 'creates a new domain' do
      @domain.region = 'uksouth'
      @domain.networkcidr = @networkcidr
      @domain.prvsubnetcidr = @prvsubnetcidr
      @domain.mgtsubnetcidr = @mgtsubnetcidr
      @domain.create
      wait_for(@domain.exists?).to be(true)
    end

    it 'should return a list of domains as a hash' do
      expect(@domain.list).to be_a(Hash)
    end

    it 'should return the correct domain information from API' do
      domain = @domain.describe
      expect(domain).to have_attributes(name: @name)
      expect(domain).to have_attributes(region: @region)
      expect(domain).to have_attributes(provider: @provider)
      expect(domain).to have_attributes(networkcidr: @networkcidr)
      expect(domain).to have_attributes(prvsubnetcidr: @prvsubnetcidr)
      expect(domain).to have_attributes(mgtsubnetcidr: @mgtsubnetcidr)
    end

    it 'should destroy the domain' do
      @domain.destroy
      wait_for(@domain.exists?).to be(false)
    end
  end

  context 'with provider aws' do
    before do
      @name = 'cloudware-aws-test'
      @provider = 'aws'
      @region = 'eu-west-1'
      @networkcidr = '10.0.0.0/16'
      @prvsubnetcidr = '10.0.1.0/24'
      @mgtsubnetcidr = '10.0.2.0/24'
      @domain = Cloudware::Domain.new
      @domain.name = @name
      @domain.provider = @provider
    end

    it 'returns correct provider' do
      expect(@domain.provider).to eq(@provider)
    end

    it 'returns the correct name' do
      expect(@domain.name).to eq(@name)
    end

    it 'returns the correct region' do
      @domain.region = @region
      expect(@domain.region).to eq(@region)
    end

    it 'returns the correct network cidr' do
      @domain.networkcidr = @networkcidr
      expect(@domain.networkcidr).to eq(@networkcidr)
    end

    it 'validates the network cidr' do
      expect(@domain.valid_cidr?(@networkcidr)).to be(true)
    end

    it 'returns the correct prv subnet cidr' do
      @domain.prvsubnetcidr = @prvsubnetcidr
      expect(@domain.prvsubnetcidr).to eq(@prvsubnetcidr)
    end

    it 'validates the prv/mgt subnet cidrs' do
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @prvsubnetcidr)).to be(true)
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @mgtsubnetcidr)).to be(true)
    end

    it 'returns the correct mgt subnet cidr' do
      @domain.mgtsubnetcidr = @mgtsubnetcidr
      expect(@domain.mgtsubnetcidr).to eq(@mgtsubnetcidr)
    end

    it 'creates a new domain' do
      @domain.region = @region
      @domain.networkcidr = @networkcidr
      @domain.prvsubnetcidr = @prvsubnetcidr
      @domain.mgtsubnetcidr = @mgtsubnetcidr
      @domain.create
      wait_for(@domain.exists?).to be(true)
    end

    it 'should return a list of domains as a hash' do
      expect(@domain.list).to be_a(Hash)
    end

    it 'should return the correct domain information from API' do
      domain = @domain.describe
      expect(domain).to have_attributes(name: @name)
      expect(domain).to have_attributes(region: @region)
      expect(domain).to have_attributes(provider: @provider)
      expect(domain).to have_attributes(networkcidr: @networkcidr)
      expect(domain).to have_attributes(prvsubnetcidr: @prvsubnetcidr)
      expect(domain).to have_attributes(mgtsubnetcidr: @mgtsubnetcidr)
    end

    it 'should destroy the domain' do
      @domain.destroy
      wait_for(@domain.exists?).to be(false)
    end
  end
end
