require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsElasticacheCluster do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elasticache = AwsClients.elasticache
      stub = elasticache.stub_data(
        :describe_cache_clusters,
        {
          cache_clusters: [
            { cache_cluster_id: 'name1' },
            { cache_cluster_id: 'name2' }
          ]
        }
      )
      elasticache.stub_responses(:describe_cache_clusters, stub)
      remote_resources = GeoEngineer::Resources::AwsElasticacheCluster._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
