# Stubs for `geo test` command
module GeoCLI::TestCmdStubs
  def self.stub!
    puts "Stubbing Commands"
    AwsClients.stub!

    # These are resource calls that aws has issues auto-creating stubs for
    kinesis_bad_stubs
    cloudfront_bad_stubs
  end

  def self.kinesis_bad_stubs
    AwsClients.kinesis.stub_responses(
      :list_streams,
      {
        stream_names: [],
        has_more_streams: false
      }
    )
  end

  def self.cloudfront_bad_stubs
    AwsClients.cloudfront.stub_responses(
      :list_cloud_front_origin_access_identities, {
        cloud_front_origin_access_identity_list: {
          items: [], marker: "marker", max_items: 100, is_truncated: false, quantity: 0
        }
      }
    )

    AwsClients.cloudfront.stub_responses(
      :list_distributions, {
        distribution_list: {
          items: [], marker: "marker", max_items: 100, is_truncated: false, quantity: 0
        }
      }
    )
  end
end
