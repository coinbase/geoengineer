require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsElasticacheReplicationGroup") do
  common_resource_tests(
    GeoEngineer::Resources::AwsElasticacheReplicationGroup,
    'aws_elasticache_replication_group'
  )

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elasticache = AwsClients.elasticache
      stub = elasticache.stub_data(
        :describe_replication_groups,
        {
          replication_groups: [
            { replication_group_id: 'rg1' },
            { replication_group_id: 'rg2' }
          ]
        }
      )
      elasticache.stub_responses(:describe_replication_groups, stub)

      replication_group_class = GeoEngineer::Resources::AwsElasticacheReplicationGroup
      remote_resources = replication_group_class._fetch_remote_resources(nil)

      expect(remote_resources.length).to eq 2
    end
  end
end
