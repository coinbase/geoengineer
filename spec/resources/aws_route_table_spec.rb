require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsRouteTable) do
  common_resource_tests(described_class, described_class.type_from_class_name)
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsRouteTable)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_route_tables,
        {
          route_tables: [
            { route_table_id: 'name1', vpc_id: "1", tags: [{ key: 'Name', value: 'one' }] },
            { route_table_id: 'name2', vpc_id: "1", tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_route_tables, stub)
      remote_resources = GeoEngineer::Resources::AwsRouteTable._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
