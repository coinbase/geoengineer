require_relative '../spec_helper'

describe "GeoEngineer::Resources::AwsCloudwatchMetricAlarm" do
  let(:aws_client) { AwsClients.cloudwatch }

  before { aws_client.setup_stubbing }
  common_resource_tests(
    GeoEngineer::Resources::AwsCloudwatchMetricAlarm,
    'aws_cloudwatch_metric_alarm'
  )

  let(:alarm_name) { 'some-fake-alarm' }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :describe_alarms,
        {
          metric_alarms: [
            { alarm_name: alarm_name },
            { alarm_name: 'another-alarm-name' }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsCloudwatchMetricAlarm._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_cloudalarm = resources.first

      expect(test_cloudalarm[:alarm_name]).to eql(alarm_name)
      expect(test_cloudalarm[:_geo_id]).to eql(alarm_name)
      expect(test_cloudalarm[:_terraform_id]).to eql(alarm_name)
    end
  end
end
