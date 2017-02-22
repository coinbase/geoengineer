require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsRedshiftCluster") do
  let(:aws_client) { AwsClients.redshift }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsRedshiftCluster, 'aws_redshift_cluster')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_clusters,
        {
          clusters: [{ cluster_identifier: "id1" }]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsRedshiftCluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(1)
    end
  end
end
