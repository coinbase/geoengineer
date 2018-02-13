################################################################################
# GithubTeamMembership is the +github_team_membership+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/team_membership.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubTeamMembership < GeoEngineer::Resource
  validate -> { validate_required_attributes([:team_id, :username]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{team_id}:#{username}" } }

  def self._fetch_remote_resources(provider)
    # There is no way to obtain all these resources in bulk in a single request,
    # so we iterate over all teams and fetch their individual memberships.
    # GitHub doesn't return the actual role of the member in the API, so we have
    # to make calls with different filters to know which role the member has.
    teams = GithubClient.organization_teams(provider.organization)
    roles = %i[maintainer member]
    jobs = teams.flat_map { |team| roles.map { |team_role| [team[:id], team_role] } }

    Parallel.map(jobs, { in_threads: Parallel.processor_count }) do |team_id, team_role|
      GithubClient.team_memberships(team_id, { role: team_role })
                  .each do |team_membership|
        team_membership[:_terraform_id] = "#{team_id}:#{team_membership[:login]}"
        team_membership[:_geo_id] = team_membership[:_terraform_id]
        team_membership[:username] = team_membership[:login]
        team_membership[:role] = team_role
      end
    end.flatten
  end
end
