require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsDbInstanceRoleAssociation do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      rds = AwsClients.rds
      stub = rds.stub_data(
        :describe_db_instances,
        {
          db_instances: [
            { db_instance_identifier: 'name1', associated_roles: [
              {
                role_arn: "somearn1",
                feature_name: "s3Import"
              },
              {
                role_arn: "somearn2",
                feature_name: "s3Import"
              }
            ] },
            { db_instance_identifier: 'name2', associated_roles: [
              {
                role_arn: "somearn3",
                feature_name: "s3Import"
              }
            ] }
          ]
        }
      )
      rds.stub_responses(:describe_db_instances, stub)
      remote_resources = GeoEngineer::Resources::AwsDbInstanceRoleAssociation._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 3
    end

    after do
      AwsClients.rds.stub_responses(:describe_db_instances, { db_instances: [] })
    end
  end
end
