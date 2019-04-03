require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsLoadBalancerListenerPolicy) do
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
              listener_descriptions: [
                {
                  listener: {
                    instance_port: 80,
                    instance_protocol: "HTTP",
                    load_balancer_port: 80,
                    protocol: "HTTP",
                  },
                  policy_names: [
                  ],
                },
                {
                  listener: {
                    instance_port: 443,
                    instance_protocol: "HTTPS",
                    load_balancer_port: 443,
                    protocol: "HTTPS",
                    ssl_certificate_id: "arn:aws:iam::123456789012:server-certificate/my-server-cert",
                  },
                  policy_names: [
                    "ELBSecurityPolicy-2015-03",
                  ],
                },
              ]
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsLoadBalancerListenerPolicy._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
      expect(remote_resources[0][:load_balancer_name]).to eq "test"
      expect(remote_resources[0][:load_balancer_port]).to eq 80
      expect(remote_resources[0][:policy_names]).to eq []
      expect(remote_resources[0][:_geo_id]).to eq "test::80"
      expect(remote_resources[0][:_terraform_id]).to eq "test:80"

      expect(remote_resources[1][:load_balancer_name]).to eq "test"
      expect(remote_resources[1][:load_balancer_port]).to eq 443
      expect(remote_resources[1][:policy_names]).to eq ["ELBSecurityPolicy-2015-03"]
      expect(remote_resources[1][:_geo_id]).to eq "test::443"
      expect(remote_resources[1][:_terraform_id]).to eq "test:443"
    end
  end
end
