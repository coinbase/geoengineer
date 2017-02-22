require_relative '../spec_helper'
require 'ostruct'

describe "GeoEngineer::Resources::AwsKmsKey" do
  let(:aws_client) { AwsClients.kms }

  before { aws_client.setup_stubbing }
  common_resource_tests(GeoEngineer::Resources::AwsKmsKey, 'aws_kms_key')

  let(:key_geo_id) { 'myid' }
  let(:key_id) { 'some-key-id' }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_keys,
        {
          keys: [
            { key_id: key_id }
          ]
        }
      )
      aws_client.stub_responses(
        :describe_key,
        {
          key_metadata: {
            key_id: key_id,
            description: key_geo_id
          }
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsKmsKey._fetch_remote_resources(nil)
      expect(resources.count).to eql 1

      test_key = resources.first

      expect(test_key[:_geo_id]).to eql(key_geo_id)
      expect(test_key[:_terraform_id]).to eql(key_id)
    end
  end
end
