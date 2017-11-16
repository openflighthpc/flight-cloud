require 'cloudware/infrastructure'
describe Cloudware::Infrastructure do
  it 'should create a new object' do
    Cloudware::Infrastructure.new
  end

  it 'should set name' do
    i = Cloudware::Infrastructure.new
    i.name = 'alces-cloudware'
    expect(i.name).to eq 'alces-cloudware'
  end

  it 'should set provider' do
    i = Cloudware::Infrastructure.new
    i.provider = 'azure'
    expect(i.provider).to eq 'azure'
  end

  it 'should set region' do
    i = Cloudware::Infrastructure.new
    i.region = 'uksouth'
    expect(i.region).to eq 'uksouth'
  end
end
