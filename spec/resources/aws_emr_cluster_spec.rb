require_relative '../spec_helper.rb'

describe GeoEngineer::Resources::AwsEmrCluster do
  let(:aws_client) { AwsClients.emr }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { aws_client.setup_stubbing }

  describe '#_fetch_remote_resources' do
    it 'should create a list of hashes from AWS SDK' do
      aws_client.stub_responses(
        :list_clusters, { clusters: [{ id: 'some-id', name: 'some-name' }] }
      )

      remote_resources = GeoEngineer::Resources::AwsEmrCluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
      remote_resource = remote_resources.first
      expect(remote_resource[:id]).to eq 'some-id'
      expect(remote_resource[:name]).to eq 'some-name'
    end
  end
end
