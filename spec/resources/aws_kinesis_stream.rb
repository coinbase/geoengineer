require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsKinesisStream") do
  common_resource_tests(GeoEngineer::Resources::AwsKinesisStream, 'aws_kinesis_stream')
end
