################################################################################
# GithubTeamRepository is the +github_team_repository+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/team_repository.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubTeamRepository < GeoEngineer::Resource
  validate -> { validate_required_attributes([:team_id, :repository]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{team_id}:#{repository}" } }

  def self._fetch_remote_resources(provider)
    # There is no way to obtain all these resources in bulk in a single request,
    # so we iterate over all teams and fetch their individual repo permissions.
    teams = GithubClient.organization_teams(provider.organization)

    Parallel.map(teams, in_threads: Parallel.processor_count) do |team, team_role|
      GithubClient.team_repositories(team[:id])
                   .each do |team_repo|
        team_repo[:_terraform_id] = "#{team[:id]}:#{team_repo[:name]}"
        team_repo[:_geo_id] = team_repo[:_terraform_id]

        team_repo[:team_id] = team[:id]
        team_repo[:repository] = team_repo[:name]

        team_repo[:permission] =
          if team_repo[:permissions][:admin]
            'admin'
          elsif team_repo[:permissions][:push]
            'push'
          elsif team_repo[:permissions][:pull]
            'pull'
          end
      end
    end.flatten
  end
end
