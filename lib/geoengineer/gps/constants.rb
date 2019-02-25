# Constants contains the needed information to
class GeoEngineer::GPS::Constants
  attr_reader :constants

  def initialize(constants)
    @constants = constants

    # the local environment overrides the default values
    constants.each_pair do |environment, vals|
      # "name" is always the full name of the environment
      constants[environment]["name"] = environment.to_s
    end

    # attach constants and environment to YamlTags
    constants.each_pair do |environment, vals|
      GeoEngineer::GPS::YamlTag.add_tag_context(vals, { constants: self, context: { environment: environment } })
    end

    @constants = HashUtils.json_dup(@constants)
  end

  def for_environment(environment_name)
    constants[environment_name.to_s]
  end

  def dereference(environment, attribute)
    # look up in environment then look in the _global
    constants.dig(environment, attribute) ||
      constants.dig("_global", attribute)
  end

  def to_h
    HashUtils.json_dup(constants)
  end
end
