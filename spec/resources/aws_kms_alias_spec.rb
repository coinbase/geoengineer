require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsKmsAlias do
  let(:aws_client) { AwsClients.kms }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  let(:arn) { "arn:aws:kms:nz-north-1:000000000000:alias/nnn" }
  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_aliases,
        {
          aliases: [
            { alias_arn: arn, alias_name: "name" }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsKmsAlias._fetch_remote_resources(nil)
      expect(resources.count).to eql 1

      expect(resources.first[:_terraform_id]).to eq arn
      expect(resources.first[:_geo_id]).to eq "name"
    end
  end
end
