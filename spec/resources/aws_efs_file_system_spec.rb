require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsEfsFileSystem) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create a list of file systems returned from the AWS sdk' do
      efs = AwsClients.efs
      stub_describe_file_systems = efs.stub_data(
        :describe_file_systems,
        {
          file_systems: [
            {
              file_system_id: "fs-01234567"
            },
            {
              file_system_id: "fs-89012345"
            }
          ]
        }
      )
      stub_describe_tags = efs.stub_data(
        :describe_tags,
        {
          tags: [
            {
              key: "Name",
              value: "thename"
            },
            {
              key: "NotName",
              value: "notthename"
            }
          ]
        }
      )
      efs.stub_responses(:describe_file_systems, stub_describe_file_systems)
      efs.stub_responses(:describe_tags, stub_describe_tags)
      remote_resources = GeoEngineer::Resources::AwsEfsFileSystem._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
      expect(remote_resources.first[:file_system_id]).to eq "fs-01234567"
      expect(remote_resources.first[:_geo_id]).to eq "thename"
    end
  end
end
