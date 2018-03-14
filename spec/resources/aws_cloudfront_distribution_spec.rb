require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCloudfrontDistribution do
  let(:aws_client) { AwsClients.cloudfront }

  before do
    # Cloudfront stubbing is broken with new api
    allow(aws_client).to receive(:list_distributions)
      .and_return({
                    distribution_list: {
                      items: [

                      ]
                    }
                  })
  end

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    let(:dist_terraform_id) { 'myid' }

    before do
      # Cloudfront stubbing is broken with new api
      allow(aws_client).to receive(:list_distributions)
        .and_return({
                      distribution_list: {
                        items: [
                          {
                            id: dist_terraform_id,
                            arn: 'arn:cloudfront:test',
                            comment: 'some-cloudfront-distribution'
                          }
                        ]
                      }
                    })
    end

    it 'creates array of hashes from AWS response' do
      resources = described_class._fetch_remote_resources(nil)
      expect(resources.count).to eq 1

      test_distribution = resources.first

      expect(test_distribution[:_terraform_id]).to eq dist_terraform_id
    end
  end
end
