# frozen_string_literal: true

require 'cloudware/domain'
require 'cloudware/azure'
require 'cloudware/aws'
require 'cloudware/config'
require 'cloudware/log'
require 'cloudware'

describe Cloudware::Domain do
  context 'with provider azure' do
    before do
      @name = 'cloudware-azure-test'
      @provider = 'azure'
      @region = 'uksouth'
      @networkcidr = '10.0.0.0/16'
      @prisubnetcidr = '10.0.1.0/24'
      @domain = described_class.new
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

    it 'returns the correct pri subnet cidr' do
      @domain.prisubnetcidr = @prisubnetcidr
      expect(@domain.prisubnetcidr).to eq(@prisubnetcidr)
    end

    it 'validates the pri subnet cidrs' do
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @prisubnetcidr)).to be(true)
    end

    xit 'creates a new domain' do
      @domain.region = 'uksouth'
      @domain.networkcidr = @networkcidr
      @domain.prisubnetcidr = @prisubnetcidr
      @domain.create
      wait_for(@domain.exists?).to be(true)
    end

    xit 'returns a list of domains as a hash' do
      expect(@domain.list).to be_a(Hash)
    end

    xit 'returns the correct domain information from API' do
      domain = @domain.describe
      expect(domain).to have_attributes(name: @name)
      expect(domain).to have_attributes(region: @region)
      expect(domain).to have_attributes(provider: @provider)
      expect(domain).to have_attributes(networkcidr: @networkcidr)
      expect(domain).to have_attributes(prisubnetcidr: @prisubnetcidr)
    end

    xit 'destroys the domain' do
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
      @prisubnetcidr = '10.0.1.0/24'
      @domain = described_class.new
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

    it 'returns the correct pri subnet cidr' do
      @domain.prisubnetcidr = @prisubnetcidr
      expect(@domain.prisubnetcidr).to eq(@prisubnetcidr)
    end

    it 'validates the pri subnet cidrs' do
      expect(@domain.is_valid_subnet_cidr?(@networkcidr, @prisubnetcidr)).to be(true)
    end

    xit 'creates a new domain' do
      @domain.region = @region
      @domain.networkcidr = @networkcidr
      @domain.prisubnetcidr = @prisubnetcidr
      @domain.create
      wait_for(@domain.exists?).to be(true)
    end

    xit 'returns a list of domains as a hash' do
      expect(@domain.list).to be_a(Hash)
    end

    xit 'returns the correct domain information from API' do
      domain = @domain.describe
      expect(domain).to have_attributes(name: @name)
      expect(domain).to have_attributes(region: @region)
      expect(domain).to have_attributes(provider: @provider)
      expect(domain).to have_attributes(networkcidr: @networkcidr)
      expect(domain).to have_attributes(prisubnetcidr: @prisubnetcidr)
    end

    xit 'destroys the domain' do
      @domain.destroy
      wait_for(@domain.exists?).to be(false)
    end
  end
end
