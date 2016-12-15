require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsMainRouteTableAssociation do
  common_resource_tests(
    GeoEngineer::Resources::AwsMainRouteTableAssociation,
    'aws_main_route_table_association'
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
              associations: [
                {
                  route_table_association_id: '1',
                  subnet_id: 's-1',
                  route_table_id: 'r-1',
                  main: false
                }
              ]
            },
            {
              route_table_id: 'name2',
              vpc_id: "1",
              tags: [{ key: 'Name', value: 'two' }],
              associations: [
                {
                  route_table_association_id: '2',
                  subnet_id: 's-2',
                  route_table_id: 'r-2',
                  main: true
                }
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
      remote_resources = described_class._fetch_remote_resources
      expect(remote_resources.length).to eq(1)
    end
  end
end
