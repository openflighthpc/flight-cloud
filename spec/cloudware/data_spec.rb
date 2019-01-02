# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Software Ltd
#
# This file is part of Alces Cloudware.
#
# Alces Cloudware is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Alces Cloudware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Alces Cloudware.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Cloudware, please visit:
# https://github.com/alces-software/cloudware
# ==============================================================================
#

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
