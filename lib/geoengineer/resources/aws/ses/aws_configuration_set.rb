########################################################################
# AwsSesConfigurationSet is the +ses_configuration_set+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/ses_configuration_set.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsSesConfigurationSet < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> {
    _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id }
  }
  after :initialize, -> {
    _geo_id -> { name.to_s }
  }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'name' => name
    }
    tfstate
  end

  def support_tags?
    false
  end
end
