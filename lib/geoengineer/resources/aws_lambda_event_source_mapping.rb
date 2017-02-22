########################################################################
# AwsLambdaEventSourceMapping is the +aws_lambda_event_source_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/lambda_event_source_mapping.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsLambdaEventSourceMapping < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([:event_source_arn, :function_name, :starting_position])
  }
  validate -> {
    if self.starting_position && !%w(TRIM_HORIZON LATEST).include?(self.starting_position)
      ["starting_position must be either TRIM_HORIZON OR LATEST"]
    end
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { [event_source_arn, function_name].join("::") } }

  def support_tags?
    false
  end

  def short_type
    "event_mapping"
  end

  def self._extract_name_from_arn(arn)
    arn_components = arn.split(":")
    arn_components[arn_components.index("function") + 1] if arn_components.index("function")
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .lambda(provider)
      .list_event_source_mappings['event_source_mappings']
      .map(&:to_h)
      .map do |event|
        geo_id = [event[:event_source_arn], self._extract_name_from_arn(event[:function_arn])]
        event.merge(
          {
            _terraform_id: event[:uuid],
            _geo_id: geo_id.join("::")
          }
        )
      end
  end
end
