########################################################################
# AwsElasticacheParameterGroup is the +aws_elasticache_parameter_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elasticache_parameter_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsElasticacheParameterGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :family, :description]) }
  validate -> { validate_subresource_required_attributes(:parameter, [:name, :value]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def short_type
    "ecpg"
  end

  def self._fetch_remote_resources
    ec = AwsClients.elasticache
    ec.describe_cache_parameter_groups['cache_parameter_groups'].map(&:to_h).map do |pg|
      pg[:_terraform_id] = pg[:cache_parameter_group_name]
      pg[:_geo_id] = pg[:cache_parameter_group_name]
      pg[:name] = pg[:cache_parameter_group_name]
      pg
    end
  end
end
