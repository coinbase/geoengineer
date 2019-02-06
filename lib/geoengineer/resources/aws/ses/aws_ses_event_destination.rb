########################################################################
# AwsSesEventDestination is the +ses_event_destination+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/ses_event_destination.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSesEventDestination < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :configuration_set_name, :matching_types]) }

  validate -> { validate_subresource_required_attributes(:sns_destination, [:topic_arn]) }

  validate -> {
    validate_subresource_required_attributes(:cloudwatch_destination,
                                             [:default_value, :dimension_name, :value_source])
  }

  validate -> {
    validate_subresource_required_attributes(:kinesis_destination, [:stream_arn, :role_arn])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  # The terraform resource does not support importing, so need to be sure
  # to retrieve the full state here because of this.
  def to_terraform_state
    tfstate = super

    tfstate[:primary][:attributes] = {
      'name' => name,
      'configuration_set_name' => configuration_set_name,
      'enabled' => enabled.to_s
    }

    tfstate[:primary][:attributes]['matching_types.#'] = (matching_types&.size || 0).to_s
    Array(matching_types).each_with_index do |t, idx|
      tfstate[:primary][:attributes]["matching_types.#{idx}"] = t
    end

    if sns_destination
      tfstate[:primary][:attributes]['sns_destination.#'] = '1'
      tfstate[:primary][:attributes]['sns_destination.1.topic_arn'] = sns_destination.topic_arn
    end

    if cloudwatch_destination
      tfstate[:primary][:attributes]['cloudwatch_destination.#'] = '1'
      tfstate[:primary][:attributes]['cloudwatch_destination.1.default_value'] = cloudwatch_destination.default_value
      tfstate[:primary][:attributes]['cloudwatch_destination.1.dimension_name'] = cloudwatch_destination.dimension_name
      tfstate[:primary][:attributes]['cloudwatch_destination.1.value_source'] = cloudwatch_destination.value_source
    end

    if kinesis_destination
      tfstate[:primary][:attributes]['kinesis_destination.#'] = '1'
      tfstate[:primary][:attributes]['kinesis_destination.1.stream_arn'] = kinesis_destination.stream_arn
      tfstate[:primary][:attributes]['kinesis_destination.1.role_arn'] = kinesis_destination.role_arn
    end

    tfstate
  end

  def self._fetch_remote_resources(provider)
    client = AwsClients.ses(provider)

    config_sets = client.list_configuration_sets[:configuration_sets].map(&:to_h).map do |config|
      client.describe_configuration_set(
        {
          configuration_set_name: config[:name],
          configuration_set_attribute_names: ["eventDestinations"]
        }
      )
    end

    destinations = config_sets.map do |config_set|
      config_set[:event_destinations]
    end.compact.flatten

    destinations.map(&:to_h).map do |d|
      d.merge(
        {
          _geo_id: d[:name],
          _terraform_id: d[:name]
        }
      )
    end
  end
end
