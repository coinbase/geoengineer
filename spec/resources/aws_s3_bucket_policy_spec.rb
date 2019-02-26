require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsS3BucketPolicy) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  after(:each) { AwsClients.clear_cache! }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      s3 = AwsClients.s3
      stub = s3.stub_data(
        :list_buckets,
        {
          buckets: [
            { name: 'name1' }
          ]
        }
      )
      s3.stub_responses(:list_buckets, stub)
      s3.stub_responses(
        :get_bucket_policy,
        s3.stub_data(:get_bucket_policy,
                     {
                       policy: {}.to_json
                     })
      )
      remote_resources = GeoEngineer::Resources::AwsS3BucketPolicy._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
