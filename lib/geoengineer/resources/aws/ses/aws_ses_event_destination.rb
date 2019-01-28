########################################################################
# AwsSesEventDestination is the +ses_event_destination+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/ses_event_destination.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSesEventDestination < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :configuration_set_name, :matching_types]) }

  after :initialize, -> { _terraform_id -> { name } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name,
      'configuration_set_name' => configuration_set_name,
      'enabled' => (enabled || 'false'),
      'matching_types' => matching_types,
      'cloudwatch_destination' => cloudwatch_destination,
      'kinesis_destination' => kinesis_destination,
      'sns_destination' => sns_destination
    }
    tfstate
  end

  def support_tags?
    false
  end
end
