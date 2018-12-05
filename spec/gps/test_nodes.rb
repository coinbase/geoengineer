class GeoEngineer::GPS::Nodes::TestNode < GeoEngineer::GPS::Node
  define_resource "aws_elb", :elb
  def json_schema
    {
      "type":  "object",
      "additionalProperties" => false,
      "properties":  {
        "name":  {
          "type":  "string",
          "default":  "default"
        }
      }
    }
  end

  def create_resources(project)
    create_elb(project)
  end
end

class GeoEngineer::GPS::Nodes::TestMetaNode < GeoEngineer::GPS::MetaNode
  def json_schema
    {
      "type":  "object",
      "additionalProperties" => false,
      "properties":  {
        "name":  {
          "type":  "string",
          "default":  "default"
        }
      }
    }
  end

  # returns node_type -> node_name -> attrs
  def build_nodes
    {
      "test_node" => {
        node_name.to_s => {
          "name" => "awsome_#{attributes['name']}"
        }
      }
    }
  end
end
