require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsLoadBalancerPolicy") do
  let(:elb_client) { AwsClients.elb }

  common_resource_tests(GeoEngineer::Resources::AwsLoadBalancerPolicy,
                        'aws_load_balancer_policy')

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
            },
            {
              policy_name: "ELBSecurityPolicy-2015-05",
              policy_type_name: "SSLNegotiationPolicyType"
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsLoadBalancerPolicy._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
