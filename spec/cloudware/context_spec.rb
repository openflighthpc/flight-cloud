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

require 'cloudware/context'

RSpec.describe Cloudware::Context do
  subject do
    build(:context).tap { |c| c.save_deployments(*deployments) }
  end

  def new_context
    build(:context)
  end

  describe 'save_deployments' do
    let(:deployments) { [] }

    it 'saves the deployment' do
      deployment = build(:deployment)
      subject.save_deployments(deployment)
      expect(new_context.deployments.first.name).to eq(deployment.name)
    end

    it 'can save multiple deployments' do
      deployments = [build(:deployment), build(:deployment, name: 'other')]
      subject.save_deployments(*deployments)
      expect(new_context.deployments.map(&:name)).to eq(deployments.map(&:name))
    end
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

    describe '#deployments' do
      it 'returns the deploument' do
        expect(subject.deployments.map(&:name)).to eq(deployments.map(&:name))
      end
    end

    describe '#save_deployments' do
      before { subject.save_deployments(new_deployment) }

      context 'with a completely new deployment' do
        let(:new_deployment) { build(:deployment, name: 'new') }

        it 'saves the new deployment to the end of the stack' do
          expect(new_context.deployments.length).to eq(2)
          expect(new_context.deployments.last.name).to eq(new_deployment.name)
        end
      end

      context 'with a deployment of the same name' do
        let(:new_results) { { single_key: 'new-value' } }
        let(:new_deployment) do
          build(:deployment, name: deployment.name, results: new_results)
        end

        it 'updates and saves the deployment' do
          expect(new_context.deployments.length).to eq(1)
          expect(new_context.deployments.first.results).to eq(new_results)
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

    describe '#remove_deployments' do
      it 'removes the deployment' do
        subject.remove_deployments(initial_deployment)
        expect(new_context.results).to eq(final_results)
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

  context 'with contention over the context file' do
    let(:deployments) { [initial_deployment] }
    let(:initial_deployment) do
      build(:deployment, name: 'initial_deployment')
    end
    let(:other_deployment) do
      build(:deployment, name: 'other-deployment')
    end
    let(:other_context) do
      described_class.new(region: subject.region, cluster: Cloudware::CommandConfig.new.current_cluster)
    end

    # Ensure the other context/deployment are created after the subject
    before do
      subject
      other_context.save_deployments(other_deployment)
    end

    it 'initially it does not include the other deployment' do
      expect(subject.find_deployment(other_deployment.name)).to be_nil
    end

    describe '#reload' do
      it 'loads the other deployment' do
        other_name = other_deployment.name
        subject.reload
        expect(subject.find_deployment(other_name)&.name).to eq(other_name)
      end
    end

    describe '#save_deployments' do
      let(:new_deployment) do
        build(:deployment, name: 'new_deployment', region: subject.region)
      end
      let(:all_names) do
        [new_deployment, initial_deployment, other_deployment].map(&:name)
      end

      before { subject.save_deployments(new_deployment) }

      it 'contains the initial, new, and other deployments' do
        expect(subject.deployments.map(&:name)).to contain_exactly(*all_names)
      end
    end

    describe '#remove_deployments' do
      context 'when deleting the initial deployment' do
        before { subject.remove_deployments(initial_deployment) }

        it 'removes the intended deployment' do
          expect(subject.find_deployment(initial_deployment.name)).to be_nil
        end

        it 'loads the other deployment into the context' do
          other_name = other_deployment.name
          expect(subject.find_deployment(other_name)&.name).to eq(other_name)
        end
      end

      it 'can delete the other deployment' do
        subject.remove_deployments(other_deployment)
        expect(subject.find_deployment(other_deployment.name)).to be_nil
      end
    end
  end
end
