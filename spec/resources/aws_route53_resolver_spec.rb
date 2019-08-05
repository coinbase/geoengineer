require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsRoute53ResolverEndpoint) do
  common_resource_tests(described_class, described_class.type_from_class_name)
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsRoute53ResolverEndpoint)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      r53r = AwsClients.route53resolver
      stub = r53r.stub_data(
        :list_resolver_endpoints, {
          next_token: nil,
          max_results: 10,
          resolver_endpoints: [{
            id: "",
            creator_request_id: "AWSConsole.34.1562114646583",
            arn: "arn:aws:route53resrslvr-in-c9eac0700bff438f9",
            name: "[FILTERED]",
            security_group_ids: ["sg-d31ec5b4"],
            direction: "INBOUND",
            ip_address_count: 2,
            host_vpc_id: "vpc-f8e36c9d",
            status: "OPERATIONAL",
            status_message: "[FILTERED]",
            creation_time: "2019-07-03T00:44:07.059Z",
            modification_time: "2019-07-03T00:44:07.059Z"
          }]
        }
      )
      r53r.stub_responses(:list_resolver_endpoints, stub)
      remote_resources = GeoEngineer::Resources::AwsRoute53ResolverEndpoint._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(1)
    end
  end
end
