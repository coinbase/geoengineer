########################################################################
# AwsDaxParameterGroup is the +aws_dax_parameter_group+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dax_parameter_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDaxParameterGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
  validate -> { validate_subresource_required_attributes(:parameter, [:name, :value]) }

  after :initialize, -> { _terraform_id -> { name } }
  after :initialize, -> { _geo_id -> { name } }

  def short_type
    "daxpg"
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    pgs = _paginate(AwsClients.dax(provider).describe_parameter_groups, 'parameter_groups')

    pgs.map(&:to_h).map do |pg|
      pg[:_terraform_id] = pg[:parameter_group_name]
      pg[:_geo_id] = pg[:parameter_group_name]
      pg[:name] = pg[:parameter_group_name]
      pg
    end
  end
end
