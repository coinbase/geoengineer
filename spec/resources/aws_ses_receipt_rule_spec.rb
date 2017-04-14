require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSesReceiptRule) do
  let(:ses_client) { AwsClients.ses }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { ses_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ses_client.stub_responses(
        :describe_active_receipt_rule_set,
        {
          rules: [
            {
              name: 'FakeRule',
              enabled: true,
              recipients: ["fake_emal@test123.com"]
            },
            {
              name: 'FakeRule',
              enabled: true,
              recipients: ["fake_emal@test123.com"]
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsSesReceiptRule._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
