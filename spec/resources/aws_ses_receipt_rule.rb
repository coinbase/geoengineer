require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSesReceiptRule") do
  common_resource_tests(GeoEngineer::Resources::AwsSesReceiptRule,
                        'aws_ses_policy')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ses = AwsClients.ses
      # ses.list_policies.policies
      stub = ses.stub_data(
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
      sns.stub_responses(:describe_active_receipt_rule_set, stub)
      remote_resources = GeoEngineer::Resources::AwsSesReceiptRule._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
