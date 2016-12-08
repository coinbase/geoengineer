require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpcDhcpOptions") do
  common_resource_tests(GeoEngineer::Resources::AwsVpcDhcpOptions, 'aws_vpc_dhcp_options')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsVpcDhcpOptions)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_dhcp_options,
        {
          dhcp_options: [
            { dhcp_options_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
            { dhcp_options_id: 'name2', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_dhcp_options, stub)
      remote_resources = GeoEngineer::Resources::AwsVpcDhcpOptions._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
