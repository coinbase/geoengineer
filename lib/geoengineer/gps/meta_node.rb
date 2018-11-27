require_relative "./node"
class GeoEngineer::GPS::MetaNode < GeoEngineer::GPS::Node
  def self.meta?
    true
  end

  def meta?
    true
  end

  # Implemented by meta-node
  def json_schema
    raise NotImplementedError
  end

  def build_nodes
    raise NotImplementedError
  end

  def create_resources(project)
    # don't do anything
  end
end