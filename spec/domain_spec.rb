require 'cloudware/domain'
require 'cloudware/azure'
require 'cloudware/aws'
describe Cloudware::Domain do
  before do
    @domain = Cloudware::Domain.new
  end
end
