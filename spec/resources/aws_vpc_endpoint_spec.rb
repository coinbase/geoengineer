require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpcEndpoint") do
  common_resource_tests(
    GeoEngineer::Resources::AwsVpcEndpoint,
    'aws_vpc_endpoint'
  )

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpc_endpoints,
        {
          vpc_endpoints: [
            {
              vpc_endpoint_id: 'name1',
              vpc_id: "1",
              service_name: "com.amazonaws.us-east-1.s3"
            },
            {
              vpc_endpoint_id: 'name1',
              vpc_id: "1",
              service_name: "com.amazonaws.us-east-1.lambda"
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpc_endpoints, stub)
    end

    after do
      ec2.stub_responses(:describe_vpc_endpoints, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpcEndpoint._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
