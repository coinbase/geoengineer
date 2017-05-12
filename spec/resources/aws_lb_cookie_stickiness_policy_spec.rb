require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLbCookieStickinessPolicy do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      elb = AwsClients.elb
      stub = elb.stub_data(
        :describe_load_balancers,
        {
          load_balancer_descriptions: [
            {
              load_balancer_name: 'name1',
              listener_descriptions: [
                { listener: { load_balancer_port: 443 }, policy_names: ['foo-bar'] }
              ],
              policies: {
                lb_cookie_stickiness_policies: [
                  { policy_name: 'foo-bar', cookie_expiration_period: 0 }
                ]
              }
            },
            {
              load_balancer_name: 'name2',
              policies: {
                lb_cookie_stickiness_policies: []
              }
            }
          ]
        }
      )
      elb.stub_responses(:describe_load_balancers, stub)
      remote_resources = described_class._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
