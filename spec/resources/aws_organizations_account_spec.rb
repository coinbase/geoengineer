require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsOrganizationsAccount do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:organizations) { AwsClients.organizations }
    before do
      stub = organizations.stub_data(
        :list_accounts,
        {
          accounts: [
            { id: 'id1', name: 'name1' },
            { id: 'id2', name: 'name2' }
          ]
        }
      )
      organizations.stub_responses(:list_accounts, stub)
    end

    after do
      organizations.stub_responses(:list_accounts, [])
    end

    it 'should create a list of accounts from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsOrganizationsAccount._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
