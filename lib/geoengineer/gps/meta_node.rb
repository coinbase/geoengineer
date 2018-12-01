require_relative "./node"
# A MetaNode is expanded into other nodes.
# The goal is that this can simplify the combination and reuse of nodes
# e.g. a serivce node, and a load balancer node could be combined into a
# service_with_load_balancer meta node
class GeoEngineer::GPS::MetaNode < GeoEngineer::GPS::Node
  def self.define_resource(type, name, id_lambda)
    raise "Meta nodes cannot define resources"
  end

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
