# Stubs for `geo test` command
module GeoCLI::TestCmdStubs
  def self.stub!
    puts "Stubbing Commands"
    AwsClients.stub!

    # This method errors for some reason
    AwsClients.kinesis.stub_responses(
      :list_streams,
      {
        stream_names: [],
        has_more_streams: false
      }
    )

    AwsClients.cloudfront.stub_responses(
      :list_cloud_front_origin_access_identities,
      {
        cloud_front_origin_access_identity_list: {
          items: [],
          marker: "marker",
          max_items: 100,
          is_truncated: false,
          quantity: 0
        }
      }
    )

    AwsClients.cloudfront.stub_responses(
      :list_distributions,
      {
        distribution_list:
        {
          items: [],
          marker: "marker",
          max_items: 100,
          is_truncated: false,
          quantity: 0
        }
      }
    )
  end
end
