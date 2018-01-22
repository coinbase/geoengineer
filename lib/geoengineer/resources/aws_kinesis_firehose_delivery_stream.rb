########################################################################
# AwsKinesisFirehoseDeliveryStream is the +aws_kinesis_firehose_delivery_stream+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_kinesis_firehose_delivery_stream.html
# Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsKinesisFirehoseDeliveryStream < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id       -> { self[:name] } }

  def support_tags?
    false
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
      if resp.delivery_stream_names != []
        options[:exclusive_start_delivery_stream_name] = resp.delivery_stream_names[-1]
      end
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
    self._all_delivery_streams(provider, names).map do |delivery_stream|
      delivery_stream.to_h.merge({
                                   _terraform_id:
                                     delivery_stream
                                       .delivery_stream_description
                                       .delivery_stream_arn,
                                   _geo_id:
                                delivery_stream
                                  .delivery_stream_description
                                  .delivery_stream_name
                                 })
    end
  end
end
