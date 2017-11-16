require 'cloudware/domain'
describe Cloudware::Domain do
  it 'should create a new object' do
    Cloudware::Domain.new
  end

  it 'should set name' do
    d = Cloudware::Domain.new
    d.name = 'alces-cloudware'
    expect(d.name).to eq 'alces-cloudware'
  end

  it 'should set provider' do
    d = Cloudware::Domain.new
    d.provider = 'azure'
    expect(d.provider).to eq 'azure'
  end
end
