# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of Flight Cloud.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# Flight Cloud is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with Flight Cloud. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on Flight Cloud, please visit:
# https://github.com/openflighthpc/flight-cloud
#===============================================================================

require 'cloudware/data'

RSpec.describe Cloudware::Data do
  let(:content) { { key: 'test content' } }
  let(:path) { '/tmp/test/file' }

  before { FileUtils.mkdir_p(File.dirname(path)) }

  shared_examples 'a data loader' do
    describe '#load' do
      it 'loads the content' do
        File.write(path, YAML.dump(content))
        expect(described_class.load(file)).to eq(content)
      end
    end

    describe '#dump' do
      it 'writes the content to the file path' do
        described_class.dump(file, content)
        expect(YAML.load_file(path)).to eq(content)
      end
    end
  end

  context 'with a string file path' do
    let(:file) { path }

    it_behaves_like 'a data loader'
  end

  context 'with a file point input' do
    let!(:file) { File.open(path, 'a+') }

    after { file.close }

    it_behaves_like 'a data loader'
  end
end
