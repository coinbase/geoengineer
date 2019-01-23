require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsOrganizationsPolicyAttachment) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:organizations) { AwsClients.organizations }
    before do
      stub1 = organizations.stub_data(
        :list_policies,
        {
          policies: [
            { id: 'name1' },
            { id: 'name2' }
          ]
        }
      )
      stub2 = organizations.stub_data(
        :list_targets_for_policy,
        {
          targets: [
            { target_id: 'name3' }
          ]
        }
      )
      organizations.stub_responses(:list_policies, stub1)
      organizations.stub_responses(:list_targets_for_policy, stub2)
    end

    after do
      organizations.stub_responses(:list_policies, [])
      organizations.stub_responses(:list_targets_for_policy, [])
    end

    it 'should create list of attachments from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsOrganizationsPolicyAttachment
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
