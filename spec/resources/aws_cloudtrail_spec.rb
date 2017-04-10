require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCloudtrail do
  let(:aws_client) { AwsClients.cloudtrail }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  let(:trail_name) { 'some-fake-cloudtrail' }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :describe_trails,
        {
          trail_list: [
            { name: trail_name },
            { name: 'another-trail-name' }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsCloudtrail._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_cloudtrail = resources.first

      expect(test_cloudtrail[:name]).to eql(trail_name)
      expect(test_cloudtrail[:_geo_id]).to eql(trail_name)
      expect(test_cloudtrail[:_terraform_id]).to eql(trail_name)
    end
  end
end
