########################################################################
# AwsEmr is the +aws_emr_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/emr_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsEmrCluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.emr(provider).list_clusters['clusters'].map(&:to_h).map do |cluster|
      cluster[:_terraform_id] = cluster[:id]
      cluster[:_geo_id] = cluster[:name]
      cluster
    end
  end
end
