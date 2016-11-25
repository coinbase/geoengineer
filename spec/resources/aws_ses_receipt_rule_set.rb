require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSesReceiptRuleSet") do
  common_resource_tests(GeoEngineer::Resources::AwsSesReceiptRuleSet,
                        'aws_ses_receipt_rule_set')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ses = AwsClients.ses
      # ses.list_receipt_rule_sets.rule_sets
      stub = ses.stub_data(
        :list_receipt_rule_sets,
        {
          rule_sets: [
            { name: "fake-rule-set", created_timestamp: "2016-10-19 20:19:29 UTC" },
            { name: "fake-rule-set-2", created_timestamp: "2016-10-19 20:19:29 UTC" }
          ]
        }
      )
      sns.stub_responses(:list_receipt_rule_sets, stub)
      remote_resources = GeoEngineer::Resources::AwsSesReceiptRuleSet._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
