require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsLoadBalancerPolicy) do
  let(:elb_client) { AwsClients.elb }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { elb_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elb_client.stub_responses(
        :describe_load_balancer_policies,
        {
          policy_descriptions: [
            {
              policy_name: "ELBSecurityPolicy-2015-05",
              policy_type_name: "SSLNegotiationPolicyType"
            }
          ]
        }
      )
      elb_client.stub_responses(
        :describe_load_balancers,
        {
          load_balancer_descriptions: [
            {
              load_balancer_name: "test",
              backend_server_descriptions: [
                {
                  instance_port: 5000,
                  policy_names: ["test"]
                }
              ]
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsLoadBalancerPolicy._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
