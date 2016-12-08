require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsCustomerGateway") do
  common_resource_tests(GeoEngineer::Resources::AwsCustomerGateway, 'aws_customer_gateway')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsCustomerGateway)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_customer_gateways,
        {
          customer_gateways: [
            { customer_gateway_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
            { customer_gateway_id: 'name2', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_customer_gateways, stub)
      remote_resources = GeoEngineer::Resources::AwsCustomerGateway._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
