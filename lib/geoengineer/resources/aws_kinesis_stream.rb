########################################################################
# AwsKinesisStream is the +aws_kinesis_stream+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_kinesis_stream.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsKinesisStream < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :shard_count]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => self.name,
      'shard_count' => self.shard_count.to_s
    }
    tfstate
  end

  def self._all_streams
    streams = []
    AwsClients.kinesis.list_streams[:stream_names].each do |stream_name|
      AwsClients.kinesis.describe_stream({ stream_name: stream_name }).map(&:to_h).map do |stream|
        streams << stream[:stream_description]
      end
    end
    streams
  end

  def self._fetch_remote_resources
    self._all_streams.map do |stream|
      stream.merge({
                     _terraform_id: stream[:stream_arn],
                     _geo_id: stream[:stream_name]
                   })
    end
  end
end
