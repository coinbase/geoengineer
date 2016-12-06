require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSubnet") do
  common_resource_tests(GeoEngineer::Resources::AwsSubnet, 'aws_subnet')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsSubnet)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_subnets,
        {
          subnets: [
            { subnet_id: '1', cidr_block: "10.120.0.0/24", tags: [{ key: 'Name', value: 'one' }] },
            { subnet_id: '2', cidr_block: "10.120.1.0/24", tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_subnets, stub)
      remote_resources = GeoEngineer::Resources::AwsSubnet._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
