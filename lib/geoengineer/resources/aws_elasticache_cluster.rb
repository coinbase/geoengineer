########################################################################
# AwsElasticacheCluster is the +aws_elasticache_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/elasticache_cluster.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsElasticacheCluster < GeoEngineer::Resource
  validate -> {
    validate_required_attributes(
      [
        :cluster_id,
        :engine,
        :node_type,
        :num_cache_nodes,
        :parameter_group_name,
        :port
      ]
    )
  }

  after :initialize, -> { _terraform_id -> { cluster_id } }

  def to_terraform_state
    tfstate = super
    attributes = {
      'port' => port.to_s,
      'parameter_group_name' => parameter_group_name
    }

    # Security groups workaround
    security_group_ids.each_with_index do |sg, i|
      attributes["security_group_ids.#{i}"] = sg._terraform_id
    end
    attributes['security_group_ids.#'] = security_group_ids.count.to_s

    tfstate[:primary][:attributes] = attributes
    tfstate
  end

  def short_type
    "ec"
  end

  def self._fetch_remote_resources
    AwsClients.elasticache.describe_cache_clusters['cache_clusters'].map(&:to_h).map do |ec|
      ec[:_geo_id] = ec[:cache_cluster_id]
      ec[:_terraform_id] = ec[:cache_cluster_id]
      ec
    end
  end
end
