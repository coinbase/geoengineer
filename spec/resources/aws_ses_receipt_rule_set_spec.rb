require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSesReceiptRuleSet") do
  let(:ses_client) { AwsClients.ses }

  common_resource_tests(GeoEngineer::Resources::AwsSesReceiptRuleSet,
                        'aws_ses_receipt_rule_set')

  before { ses_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ses_client.stub_responses(
        :list_receipt_rule_sets,
        {
          rule_sets: [
            {
              name: "fake-rule-set",
              created_timestamp: Time.parse("2016-10-19 20:19:29 UTC")
            },
            {
              name: "fake-rule-set-2",
              created_timestamp: Time.parse("2016-10-19 20:19:29 UTC")
            }
          ]
        }
      )
      remote_resources = GeoEngineer::Resources::AwsSesReceiptRuleSet._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
