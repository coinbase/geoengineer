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

  def self._all_streams(provider)
    streams = []
    AwsClients.kinesis(provider).list_streams[:stream_names].each do |stream_name|
      descriptions = AwsClients
                     .kinesis
                     .describe_stream({ stream_name: stream_name })
                     .map(&:stream_description)
                     .map(&:to_h)
      streams << _merge_stream_descriptions(descriptions)
    end
    streams
  end

  # By default, if a stream has more than 100 shards, it will return multiple responses
  # for a single stream, and you have to manually combine the descriptions
  def self._merge_stream_descriptions(descriptions)
    descriptions.each_with_object({}) do |description, stream|
      stream.merge!(description) do |key, existing_value, new_value|
        if key == :shards
          existing_value.concat(new_value)
        else
          new_value
        end
      end
    end
  end

  def self._fetch_remote_resources(provider)
    self._all_streams(provider).map do |stream|
      stream.merge({
                     _terraform_id: stream[:stream_arn],
                     _geo_id: stream[:stream_name]
                   })
    end
  end
end
