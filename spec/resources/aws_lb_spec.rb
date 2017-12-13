require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLb do
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
        :describe_tags,
        {
          tag_descriptions: [
            {
              resource_arn: "foo/bar-baz",
              tags: [{ key: "Name", value: "foo/bar-baz" }]
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsLb._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end

    it "should work if no ALB's exist" do
      alb_client.stub_responses(:describe_load_balancers, { load_balancers: [] })

      remote_resources = GeoEngineer::Resources::AwsLb._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 0
    end
  end
end
