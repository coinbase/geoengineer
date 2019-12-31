require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsInternetGateway) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_internet_gateways,
        {
          internet_gateways: [
            { internet_gateway_id: 'name1', tags: [{ key: 'Name', value: 'one' }], attachments: [{ vpc_id: 'vpc-123' }] },
            { internet_gateway_id: 'name2', tags: [{ key: 'Name', value: 'two' }], attachments: [{ vpc_id: 'vpc-456' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_internet_gateways, stub)
      remote_resources = GeoEngineer::Resources::AwsInternetGateway._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
