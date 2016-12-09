require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsRoute53Record") do
  let(:aws_client) { AwsClients.route53 }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsRoute53Record, 'aws_route53_record')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_hosted_zones,
        {
          hosted_zones: [
            { id: 'id1', name: "zone1", caller_reference: "foo" }
          ],
          is_truncated: false,
          max_items: 100,
          marker: "foo"
        }
      )
      aws_client.stub_responses(
        :list_resource_record_sets,
        {
          resource_record_sets: [
            { name: 'name1', type: 'A', ttl: 3600, resource_records: [{ value: "8.8.8.8" }] },
            { name: 'name1', type: 'CNAME', ttl: 300, resource_records: [{ value: "0.0.0.0" }] }
          ],
          is_truncated: false,
          max_items: 100
        }
      )
    end

    after do
      aws_client.stub_responses(:list_hosted_zones, [])
      aws_client.stub_responses(:list_resource_record_sets, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsRoute53Record._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
