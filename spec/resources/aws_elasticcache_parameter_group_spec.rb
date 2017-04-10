require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsElasticacheParameterGroup do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elasticache = AwsClients.elasticache
      stub = elasticache.stub_data(
        :describe_cache_parameter_groups,
        {
          cache_parameter_groups: [
            { cache_parameter_group_name: 'name1' },
            { cache_parameter_group_name: 'name2' }
          ]
        }
      )
      elasticache.stub_responses(:describe_cache_parameter_groups, stub)
      rr = GeoEngineer::Resources::AwsElasticacheParameterGroup._fetch_remote_resources(nil)
      expect(rr.length).to eq 2
    end
  end
end
