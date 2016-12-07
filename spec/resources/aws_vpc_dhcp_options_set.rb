require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpcDhcpOption") do
  common_resource_tests(GeoEngineer::Resources::AwsVpcDhcpOption, 'aws_vpc_dhcp_option')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsVpcDhcpOption)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_dhcp_options,
        {
          vpc_dhcp_options: [
            { dhcp_option_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
            { dhcp_option_id: 'name2', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_vpc_dhcp_options, stub)
      remote_resources = GeoEngineer::Resources::AwsVpcDhcpOption._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
