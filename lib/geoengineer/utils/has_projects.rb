########################################################################
# HasProjects provides methods for a class to contain and query a set of projects
########################################################################
module HasProjects
  def projects
    @_projects ||= {}
  end

  # Factory for creating projects inside an environment
  def project(org, name, &block)
    # do not add the project a second time
    repository = "#{org}/#{name}"
    return projects[repository] if projects.key?(repository)

    project = GeoEngineer::Project.new(org, name, self, &block)

    supported_environments = [project.environments].flatten
    # do not add the project if the project is not supported by this environment
    return NullObject.new unless supported_environments.include? @name

    projects[name] = project
  end

  def all_project_resources
    projects.values.map(&:all_resources).flatten
  end
end
