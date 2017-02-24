require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSqsQueue") do
  common_resource_tests(GeoEngineer::Resources::AwsSqsQueue, 'aws_sqs_queue')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      sqs = AwsClients.sqs
      stub = sqs.stub_data(
        :list_queues,
        {
          queue_urls: ["https://www.qqq.com/path/name1", "https://www.qqq.com/path/name2"]
        }
      )
      sqs.stub_responses(:list_queues, stub)
      remote_resources = GeoEngineer::Resources::AwsSqsQueue._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
