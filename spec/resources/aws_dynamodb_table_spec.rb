require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsDynamodbTable" do
  let(:aws_client) { AwsClients.dynamo }

  common_resource_tests(GeoEngineer::Resources::AwsDynamodbTable, 'aws_dynamodb_table')

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_tables, { table_names: ["dynamo_name1", "dynamo_name2"] }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsDynamodbTable._fetch_remote_resources
      expect(resources.count).to eql 2

      test_dynamot = resources.first
      expect(test_dynamot[:_terraform_id]).to eql "dynamo_name1"
      expect(test_dynamot[:_geo_id]).to eql "dynamo_name1"
    end
  end
end
