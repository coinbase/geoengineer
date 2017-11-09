require_relative '../spec_helper.rb'

describe GeoEngineer::Resources::AwsEmrCluster do
  let(:aws_client) { AwsClients.emr }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { aws_client.setup_stubbing }

  describe '#_fetch_remote_resources' do
    it 'creates a list of hashes from AWS SDK' do
      aws_client.stub_responses(
        :list_clusters, { clusters: [{ id: 'some-id', name: 'some-name' }] }
      )

      remote_resources = GeoEngineer::Resources::AwsEmrCluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
      remote_resource = remote_resources.first
      expect(remote_resource[:id]).to eq 'some-id'
      expect(remote_resource[:name]).to eq 'some-name'
    end

    it 'ignores terminated clusters' do
      aws_client.stub_responses(
        :list_clusters,
        {
          clusters: [
            { id: 'j-XXXXXXXXXXXX1',
              name: 'some-name' },
            { id: 'j-XXXXXXXXXXXX2',
              name: 'some-name',
              status: { state: 'TERMINATED' } },
            { id: 'j-XXXXXXXXXXXX3',
              name: 'some-name',
              status: { state: 'TERMINATED_WITH_ERRORS' } },
            { id: 'j-XXXXXXXXXXXX4',
              name: 'some-name',
              status: { state: 'TERMINATING' } }
          ]
        }
      )

      remote_resources = GeoEngineer::Resources::AwsEmrCluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
      remote_resource = remote_resources.first
      expect(remote_resource[:id]).to eq 'j-XXXXXXXXXXXX1'
      expect(remote_resource[:name]).to eq 'some-name'
    end
  end
end
