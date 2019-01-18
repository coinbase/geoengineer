require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsOrganizationsOrganization) do
  describe "class mapping" do
    mapping_tests(described_class, described_class.type_from_class_name)
  end

  describe "#_fetch_remote_resources" do
    let(:organizations) { AwsClients.organizations }
    before do
      stub = organizations.stub_data(
        :describe_organization,
        {
          organization: { id: 'name1' }
        }
      )
      organizations.stub_responses(:describe_organization, stub)
    end

    after do
      organizations.stub_responses(:describe_organization, {})
    end

    it 'should create an organization hash from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsOrganizationsOrganization
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(1)
    end
  end
end
