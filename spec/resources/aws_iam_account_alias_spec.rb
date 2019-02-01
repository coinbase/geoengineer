require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsIamAccountAlias do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:iam) { AwsClients.iam }
    before do
      stub = iam.stub_data(
        :list_account_aliases,
        {
          account_aliases: [
            'alias1'
          ]
        }
      )
      iam.stub_responses(:list_account_aliases, stub)
    end

    after do
      iam.stub_responses(:list_account_aliases, [])
    end

    it 'should create a list of accounts from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsIamAccountAlias._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
