require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsNetworkAcl") do
  common_resource_tests(GeoEngineer::Resources::AwsNetworkAcl, 'aws_network_acl')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsNetworkAcl)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_network_acls,
        {
          network_acls: [
            { network_acl_id: 'name1', vpc_id: "1", tags: [{ key: 'Name', value: 'one' }] },
            { network_acl_id: 'name2', vpc_id: "1", tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_network_acls, stub)
      remote_resources = GeoEngineer::Resources::AwsNetworkAcl._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
