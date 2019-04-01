###############################################################################################
# AwsElasticacheSubnetGroup is the +aws_elasticache_subnet_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elasticache_subnet_group.html Terraform Docs}
##################################################################################################
class GeoEngineer::Resources::AwsElasticacheSubnetGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :subnet_ids]) }

  after :initialize, -> { _terraform_id -> { name } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = { "name" => name }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    cache_subnet_groups = AwsClients.elasticache(provider).describe_cache_subnet_groups

    cache_subnet_groups['cache_subnet_groups'].map(&:to_h).map do |csg|
      csg[:name] = csg[:cache_subnet_group_name]
      csg[:_terraform_id] = csg[:cache_subnet_group_name]
      csg[:_geo_id] = csg[:cache_subnet_group_name]
      csg
    end
  end
end
