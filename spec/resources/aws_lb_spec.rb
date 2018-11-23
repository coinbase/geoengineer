require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLb do
  let(:alb_client) { AwsClients.alb }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before do
    alb_client.setup_stubbing
    alb_client.stub_responses(:describe_tags, ->(context) {
      arns = context.params[:resource_arns]

      resp = { tag_descriptions: [] }

      arns.each do |arn|
        resp[:tag_descriptions] << {
          resource_arn: arn,
          tags: [{ key: "Name", value: arn }]
        }
      end

      resp
    })
  end

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      alb_client.stub_responses(
        :describe_load_balancers,
        {
          load_balancers: [{ load_balancer_arn: "foo/bar-baz" }]
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

    it 'will work with > 20 ALBs' do
      arns = (1..21).map { |i| { load_balancer_arn: "foo/repo-#{i}" } }
      alb_client.stub_responses(:describe_load_balancers, { load_balancers: arns })

      remote_resources = GeoEngineer::Resources::AwsLb._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 21
    end
  end
end
