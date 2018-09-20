require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsIamSamlProvider) do
  let(:aws_client) { AwsClients.iam }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)
  describe '#_fetch_remote_resources' do
    before do
      list_resp = double()
      saml_resp = double()
      allow(saml_resp).to receive(:arn).and_return(
        "arn:aws:iam::123456789012:saml-provider/ADFSProvider"
      )
      allow(list_resp).to receive(:saml_provider_list).and_return([saml_resp])
      aws_client.stub_responses(:list_saml_providers, list_resp)
    end

    after { aws_client.stub_responses(:list_saml_providers, {}) }

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsIamSamlProvider._fetch_remote_resources(nil)
      expect(resources.count).to eql(1)
    end
  end
end
