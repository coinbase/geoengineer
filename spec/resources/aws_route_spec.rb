require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsRoute") do
  common_resource_tests(
    GeoEngineer::Resources::AwsRoute,
    'aws_route'
  )

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_route_tables,
        {
          route_tables: [
            {
              route_table_id: 'name1',
              vpc_id: "1",
              tags: [{ key: 'Name', value: 'one' }],
              routes: [
                { destination_cidr_block: "0.0.0.0/0" }
              ]
            },
            {
              route_table_id: 'name2',
              vpc_id: "1",
              tags: [{ key: 'Name', value: 'two' }],
              routes: [
                { destination_cidr_block: "0.0.0.0/0" }
              ]
            }
          ]
        }
      )
      ec2.stub_responses(:describe_route_tables, stub)
    end

    after do
      ec2.stub_responses(:describe_route_tables, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsRoute._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
