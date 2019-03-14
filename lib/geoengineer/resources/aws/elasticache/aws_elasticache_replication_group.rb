###############################################################################################
# AwsElasticacheReplicationGroup is the +aws_elasticache_replication_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elasticache_replication_group.html Terraform Docs}
##################################################################################################
class GeoEngineer::Resources::AwsElasticacheReplicationGroup < GeoEngineer::Resource
  validate -> {
    validate_required_attributes(
      [
        :replication_group_id,
        :replication_group_description,
        :number_cache_clusters,
        :node_type,
        :port
      ]
    )
  }

  after :initialize, -> { _terraform_id -> { replication_group_id } }

  def to_terraform_state
    tfstate = super

    attributes = {}

    # Workaround for availability zones
    availability_zones.each_with_index do |az, i|
      attributes["availability_zones.#{i}"] = az
    end
    attributes['availability_zones.#'] = availability_zones.count.to_s
    attributes['tags.%'] = tags.attributes.keys.count.to_s

    tags.attributes.each do |(key, value)|
      attributes["tags.#{key}"] = value.to_s
    end

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def self._fetch_remote_resources(provider)
    ec = AwsClients.elasticache(provider)
    ec.describe_replication_groups['replication_groups'].map(&:to_h).map do |rg|
      rg[:_terraform_id] = rg[:replication_group_id]
      rg[:_geo_id] = rg[:replication_group_id]
      rg
    end
  end
end
