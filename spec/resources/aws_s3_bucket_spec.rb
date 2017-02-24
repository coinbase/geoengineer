require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsS3Bucket") do
  common_resource_tests(GeoEngineer::Resources::AwsS3Bucket, 'aws_s3_bucket')

  describe "validations" do
    it 'should validate that policy is valid JSON' do
      s3b = GeoEngineer::Resources::AwsS3Bucket.new('type', 'id') {
        bucket "bucket"
        policy "}}" # invalid JSON
      }
      expect(s3b.errors.length).to eq 1

      s3g = GeoEngineer::Resources::AwsS3Bucket.new('type', 'id') {
        bucket "bucket"
        policy "{}" # valid JSON
      }
      expect(s3g.errors.length).to eq 0
    end
  end

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      s3 = AwsClients.s3
      stub = s3.stub_data(
        :list_buckets,
        {
          buckets: [
            { name: 'name1' },
            { name: 'name2' }
          ]
        }
      )
      s3.stub_responses(:list_buckets, stub)
      remote_resources = GeoEngineer::Resources::AwsS3Bucket._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
