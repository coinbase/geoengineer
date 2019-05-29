########################################################################
# AwsKinesisFirehoseDeliveryStream is the +aws_kinesis_firehose_delivery_stream+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/kinesis_firehose_delivery_stream.html
# Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsKinesisFirehoseDeliveryStream < GeoEngineer::Resource
  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name }
  }

  def support_tags?
    true
  end

  def short_type
    'firehose'
  end

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => self.name
    }

    # Ignore s3 configuration if its extended_s3 as it sets defaults.
    default_s3_configuration(tfstate) if self.destination == 'extended_s3'

    # Kinesis source isn't getting set properly in the aws terraform provider
    update_kinesis_source(tfstate) if self.kinesis_source_configuration

    tfstate
  end

  def self._all_delivery_stream_names(provider)
    options = { limit: 100 }
    has_more = true
    streams = []
    while has_more
      resp = AwsClients.firehose(provider)
                       .list_delivery_streams(options)

      streams += resp.delivery_stream_names
      has_more = resp.has_more_delivery_streams
      options[:exclusive_start_delivery_stream_name] = resp.delivery_stream_names[-1] if resp.delivery_stream_names != []
    end
    streams
  end

  def self._all_delivery_streams(provider, names)
    names.map do |name|
      AwsClients.firehose(provider)
                .describe_delivery_stream({ delivery_stream_name: name })
    end
  end

  def self._fetch_remote_resources(provider)
    names = self._all_delivery_stream_names(provider)
    streams = self._all_delivery_streams(provider, names).map(&:to_h)
    streams.map do |ds|
      ds[:_terraform_id] = ds[:delivery_stream_description][:delivery_stream_arn]
      ds[:_geo_id] = ds[:delivery_stream_description][:delivery_stream_name]
      ds[:name] = ds[:delivery_stream_description][:_geo_id]
      ds
    end
  end

  private

  def default_s3_configuration(tfstate)
    tfstate[:primary][:attributes]["s3_configuration.0.buffer_interval"] = "300"
    tfstate[:primary][:attributes]["s3_configuration.0.buffer_size"] = "5"
    tfstate[:primary][:attributes]["s3_configuration.0.compression_format"] = "UNCOMPRESSED"

    tfstate
  end

  def update_kinesis_source(tfstate)
    tfstate[:primary][:attributes]["kinesis_source_configuration.#"] = "1"
    tfstate[:primary][:attributes]["kinesis_source_configuration.0.kinesis_stream_arn"] =
      self.kinesis_source_configuration.kinesis_stream_arn
    tfstate[:primary][:attributes]["kinesis_source_configuration.0.role_arn"] =
      self.kinesis_source_configuration.role_arn

    tfstate
  end
end
