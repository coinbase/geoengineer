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
  end
end
