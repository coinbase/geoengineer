require_relative '../spec_helper'

# rubocop:disable Metrics/LineLength
describe(GeoEngineer::Resources::AwsVpcEndpointService) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpc_endpoint_service_configurations,
        {
          service_configurations: [
            {
              network_load_balancer_arns: ["arn:aws:elasticloadbalancing:us-east-1:564673040929:loadbalancer/net/selector-infra-kibana-selector/5a47c79db0c1e026"],
              service_id: "vpce-svc-074c6c22be3c14678"
            },
            {
              network_load_balancer_arns: ["arn:aws:elasticloadbalancing:us-east-1:564673040929:loadbalancer/net/selector-infra-kibana-selector2/5a47c79db0c1e027"],
              service_id: "vpce-svc-074c6c22be3c14679"
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpc_endpoint_service_configurations, stub)
    end

    after do
      ec2.stub_responses(:describe_vpc_endpoint_service_configurations, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpcEndpointService._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
# rubocop:enable Metrics/LineLength
