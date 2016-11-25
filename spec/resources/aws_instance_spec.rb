require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsInstance") do
  common_resource_tests(GeoEngineer::Resources::AwsInstance, 'aws_instance')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsInstance)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_instances,
        {
          reservations: [
            instances: [
              { instance_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
              { instance_id: 'name2', tags: [{ key: 'Name', value: 'two' }] }
            ]
          ]
        }
      )
      ec2.stub_responses(:describe_instances, stub)
      remote_resources = GeoEngineer::Resources::AwsInstance._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
