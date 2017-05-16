require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsAlbListener do
  let(:alb_client) { AwsClients.alb }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { alb_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      alb_client.stub_responses(
        :describe_load_balancers,
        {
          load_balancers: [{ load_balancer_arn: "foo/bar-baz" }]
        }
      )
      alb_client.stub_responses(
        :describe_listeners,
        {
          listeners: [
            {
              load_balancer_arn: "foo/bar-baz",
              port: 443
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsAlbListener._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
