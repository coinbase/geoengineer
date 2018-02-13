################################################################################
# GithubTeam is the +github_team+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/team.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubTeam < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    GithubClient.organization_teams(provider.organization)
                .each do |team|
      team[:_terraform_id] = team[:id].to_s
      team[:_geo_id] = team[:name]
    end
  end
end
