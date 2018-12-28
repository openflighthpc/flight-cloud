# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2018 Stephen F. Norledge and Alces Software Ltd
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

require 'cloudware/models/context'

RSpec.describe Cloudware::Models::Context do
  subject do
    build(:context, deployments: deployments)
  end

  context 'with a single deployment' do
    let(:results) { { single_key: 'value' } }
    let(:deployment) { build(:deployment, results: results) }
    let(:deployments) { [deployment] }

    describe '#results' do
      it "returns the deployment's results" do
        expect(subject.results).to eq(deployments.first.results)
      end
    end

    describe '#save' do
      it 'saves the context so it can be reloaded' do
        subject.save
        new_context = build(:context)
        expect(new_context.results).to eq(subject.results)
      end

      context 'with updated deployment results' do
        let(:updated_results) { { single_key: 'something else' } }

        before { deployment.results = updated_results }

        it 'saves updated deployment results' do
          subject.save
          new_context = build(:context)
          expect(new_context.results).to eq(updated_results)
        end
      end
    end

    describe '#deployments' do
      it 'returns the deploument' do
        expect(subject.deployments.map(&:name)).to eq(deployments.map(&:name))
      end
    end

    describe '#deployments=' do
      it 'sets the deployment' do
        expect(subject.results).to eq(results)
      end

      it 'replaces existing deployments' do
        subject.deployments = [build(:deployment)]
        expect(subject.results).to eq({})
      end
    end

    describe '#with_deployment' do
      before { subject.with_deployment(new_deployment) }

      context 'with a completely new deployment' do
        let(:new_deployment) { build(:deployment, name: 'new') }

        it 'adds new deployments to the end of the stack' do
          expect(subject.deployments.length).to eq(2)
          expect(subject.deployments.last).to eq(new_deployment)
        end
      end

      context 'with a deployment of the same name' do
        let(:new_results) { { single_key: 'new-value' } }
        let(:new_deployment) do
          build(:deployment, name: deployment.name, results: new_results)
        end

        it 'updates existing deployment' do
          expect(subject.deployments.length).to eq(1)
          expect(subject.deployments.first.results).to eq(new_results)
        end
      end
    end
  end

  context 'with two deployments' do
    let(:initial_results) { { key: 'value', replaced_key: 'wrong' } }
    let(:final_results) { { replaced_key: 'correct' } }
    let(:merged_results) { initial_results.merge(final_results) }

    let(:initial_deployment) { build(:deployment, results: initial_results) }
    let(:final_deployment) do
      build(:deployment, name: 'final', results: final_results)
    end
    let(:deployments) { [initial_deployment, final_deployment] }

    describe '#results' do
      it 'replaces the earlier results with the latter' do
        expect(subject.results).to eq(merged_results)
      end
    end

    describe '#remove_deployment' do
      it 'removes the deployment' do
        subject.remove_deployment(initial_deployment)
        expect(subject.results).to eq(final_results)
      end
    end

    describe '#find_deployment' do
      it 'returns nil if the deployment is missing' do
        expect(subject.find_deployment('missing')).to be_nil
      end

      it 'returns the deployment' do
        name = final_deployment.name
        expect(subject.find_deployment(name)).to eq(final_deployment)
      end
    end
  end
end
