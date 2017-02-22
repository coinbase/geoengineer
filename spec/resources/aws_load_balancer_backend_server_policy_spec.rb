require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLoadBalancerBackendServerPolicy do
  let(:elb_client) { AwsClients.elb }

  common_resource_tests(GeoEngineer::Resources::AwsLoadBalancerBackendServerPolicy,
                        'aws_load_balancer_backend_server_policy')

  before { elb_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
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
            },
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
      remote_resources = described_class._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
