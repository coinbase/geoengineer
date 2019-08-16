########################################################################
# GeoEngineer main Module
########################################################################
module GeoEngineer
end

########################################################################
# GeoEngineer::Resources Collection of Resources
########################################################################
module GeoEngineer::Resources
end

########################################################################
# GeoEngineer::Templates Collection of Templates
########################################################################
module GeoEngineer::Templates
end

########################################################################
# GeoEngineer::GPS Geo Planning System
########################################################################
class GeoEngineer::GPS
end

# GPS Nodes module contains the node definitions
module GeoEngineer::GPS::Nodes
end

require 'json'
require 'octokit'
require 'ostruct'
require 'uri'
require 'securerandom'
require 'pg'

Dir["#{File.dirname(__FILE__)}/geoengineer/utils/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/gps/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/resources/**/*.rb"].each { |f| require f }

Dir["#{File.dirname(__FILE__)}/geoengineer/templates/**/*.rb"].each { |f| require f }

# Require only the GeoCLI
require "#{File.dirname(__FILE__)}/geoengineer/cli/geo_cli.rb"
