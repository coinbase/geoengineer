require 'tty-pager'

########################################################################
# GPSCommands provides command line GPS related tooling
# +query+ for GPS nodes
########################################################################
module GeoCLI::GPSCommands
  class QueryError < StandardError; end

  QUERY_SYNTAX = %r{
    (?<project>[a-zA-Z0-9\-_/*]+):         # Match the project name (required)
    (?<environment>[a-zA-Z0-9\-_*]+):      # Match the environment (required)
    (?<configuration>[a-zA-Z0-9\-_*]+):    # Match the configuration (required)
    (?<node_type>[a-zA-Z0-9\-_*]+):        # Match the node_type (required)
    (?<node_name>[a-zA-Z0-9\-_/*.]+)       # Match the node_name (required)
  }x

  def format_nodes(nodes, expanded = false, attributes_to_show = nil)
    nodes.map do |node|
      attributes = expanded ? node.attributes : node.initial_attributes

      unless attributes_to_show.nil?
        attributes = attributes.select { |name| attributes_to_show.include?(name) }
      end

      output = if attributes.empty?
                 "N/A"
               else
                 strip_leading_line(attributes.to_yaml)
               end

      ">> #{node.node_id}\n#{output}"
    end.join("\n\n") + "\n"
  end

  def strip_leading_line(yaml)
    yaml.split("\n")[1..-1].join("\n")
  end

  def validate_query!(query)
    raise QueryError, "#{query} does not match the query syntax, please try again" unless query.match?(QUERY_SYNTAX)
  end

  def return_results(nodes, output_path = nil)
    if output_path.nil?
      TTY::Pager.new.page(nodes)
    else
      File.write(output_path, nodes)
    end
  end

  def query_cmd
    command :query do |c|
      c.syntax = './geo query <query> --attributes ATTRIBUTES --expanded'
      c.description = 'Query the GPS graph'
      c.option '--attributes ATTRIBUTES', Array, 'List of attributes to show for each matching node'
      c.option '--expanded', 'If true, display the attributes with defaults inserted'
      c.option '--out PATH', String, 'File path to store output'

      c.action do |args, options|
        options.default({ environment: "development", expanded: false })
        require_environment(options)

        query = args.first
        validate_query!(query)
        matching_nodes = gps.where(query)

        return "No matching nodes found for query: #{query}" if matching_nodes.empty?
        say "Found #{matching_nodes.length} nodes..."

        return_results(
          format_nodes(matching_nodes, options.expanded, options.attributes),
          options.out
        )
      end
    end
  end
end
