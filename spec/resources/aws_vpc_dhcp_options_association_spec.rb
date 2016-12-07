require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpcDhcpOptionsAssociation") do
  common_resource_tests(
    GeoEngineer::Resources::AwsVpcDhcpOptionsAssociation,
    'aws_vpc_dhcp_options_association'
  )

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpcs,
        {
          vpcs: [
            {
              vpc_id: 'name1',
              cidr_block: "10.120.0.0/24",
              tags: [{ key: 'Name', value: 'one' }],
              dhcp_options_id: '1'
            },
            {
              vpc_id: 'name2',
              cidr_block: "10.120.1.0/24",
              tags: [{ key: 'Name', value: 'two' }],
              dhcp_options_id: '2'
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpcs, stub)
    end

    after do
      ec2.stub_responses(:describe_vpcs, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpc._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
