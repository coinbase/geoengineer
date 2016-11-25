require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsElasticsearchDomain") do
  common_resource_tests(GeoEngineer::Resources::AwsElasticsearchDomain, 'aws_elasticsearch_domain')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      stub = AwsClients.elasticsearch.stub_data(
        :list_domain_names,
        {
          domain_names: [
            { domain_name: 'name1' },
            { domain_name: 'name2' }
          ]
        }
      )
      AwsClients.elasticsearch.stub_responses(:list_domain_names, stub)
      remote_resources = GeoEngineer::Resources::AwsElasticsearchDomain._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
