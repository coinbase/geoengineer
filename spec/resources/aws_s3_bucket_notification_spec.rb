require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsS3BucketNotification) do
  common_resource_tests(described_class, described_class.type_from_class_name)
end
