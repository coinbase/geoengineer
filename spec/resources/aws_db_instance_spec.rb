require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsDbInstance") do
  common_resource_tests(GeoEngineer::Resources::AwsDbInstance, 'aws_db_instance')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      rds = AwsClients.rds
      stub = rds.stub_data(
        :describe_db_instances,
        {
          db_instances: [
            { db_instance_identifier: 'name1' },
            { db_instance_identifier: 'name2' }
          ]
        }
      )
      rds.stub_responses(:describe_db_instances, stub)
      remote_resources = GeoEngineer::Resources::AwsDbInstance._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
