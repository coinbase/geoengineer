require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsVpc) do
  common_resource_tests(described_class, described_class.type_from_class_name)
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsVpc)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_vpcs,
        {
          vpcs: [
            { vpc_id: 'name1', cidr_block: "10.10.0.0/24", tags: [{ key: 'Name', value: 'one' }] },
            { vpc_id: 'name2', cidr_block: "10.10.1.0/24", tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_vpcs, stub)
      remote_resources = GeoEngineer::Resources::AwsVpc._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
