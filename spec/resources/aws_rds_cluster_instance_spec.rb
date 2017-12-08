require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsRdsClusterInstance do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_is_aurora?" do
    it 'determines if an rds is of type aurora' do
      aurora_rds = { storage_type: 'aurora' }
      non_aurora_rds = { storage_type: 'gp2' }

      expect(GeoEngineer::Resources::AwsRdsClusterInstance._is_aurora?(aurora_rds)).to eq true
      expect(GeoEngineer::Resources::AwsRdsClusterInstance._is_aurora?(non_aurora_rds)).to eq false
    end
  end

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      rds = AwsClients.rds
      stub = rds.stub_data(
        :describe_db_instances,
        {
          db_instances: [
            { db_instance_identifier: 'name1', storage_type: 'aurora' },
            { db_instance_identifier: 'name2', storage_type: 'gp2' }
          ]
        }
      )
      rds.stub_responses(:describe_db_instances, stub)
      remote_resources = GeoEngineer::Resources::AwsRdsClusterInstance._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
