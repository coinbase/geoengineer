########################################################################
# AwsDaxCluster is the +aws_dax_cluster+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dax_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsDaxCluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_name]) }

  after :initialize, -> { _terraform_id -> { name } }
  after :initialize, -> { _geo_id -> { name } }

  def short_type
    'dax_cluster'
  end

  def self._fetch_remote_resources(provider)
    clusters = _paginate(AwsClients.dax(provider).describe_clusters, 'clusters')

    clusters.map(&:to_h).map do |cluster|
      cluster[:_terraform_id] = cluster[:cluster_name]
      cluster[:_geo_id]       = cluster[:cluster_name]
      cluster[:name]          = cluster[:cluster_name]
      cluster
    end
  end
end
