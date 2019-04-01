require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsDbSubnetGroup do
  let(:aws_client) { AwsClients.rds }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_db_subnet_groups,
        {
          db_subnet_groups: [
            { db_subnet_group_name: 'db-subnet-group-1' },
            { db_subnet_group_name: 'db-subnet-group-2' }
          ]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsDbSubnetGroup
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
