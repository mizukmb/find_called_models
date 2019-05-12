require "find_called_models/railtie"
require 'logger'

class Rails::Rack::Logger
  module Starter
    def started_request_message(request)
        ModelsFinder.logger_debug '--- Start Models Finder ---'
        ModelsFinder.init!

        super
    end
  end
  prepend Starter
end

ActiveSupport.on_load :active_record do
  class ActiveRecord::Relation
    module Finder
      def initialize(klass, table: klass.arel_table, predicate_builder: klass.predicate_builder, values: {})
        ModelsFinder.logger_debug "\tFind -> #{klass}"
        ModelsFinder.add klass

        super(klass, table: klass.arel_table, predicate_builder: klass.predicate_builder, values: {})
      end
    end
    prepend Finder
  end
end

ActiveSupport.on_load :action_controller do
  class ActionController::LogSubscriber
    module Finisher
      def process_action(event)
        ModelsFinder.logger_debug '--- Finish Models Finder ---'
        ModelsFinder.logger_debug 'Models Finder Result'
        ModelsFinder.print
        ModelsFinder.clear!
        
        super
      end
    end
    prepend Finisher
  end
end

class ModelsFinder
  def self.init!
    @@finder ||= {}
  end

  def self.add(model_name)
    @@finder[model_name.to_s] = @@finder[model_name.to_s].to_i + 1
  end

  def self.print
    str = "\n"
    @@finder.each do |k, v|
      str += "\t#{k}: #{v}\n"
    end

    logger_debug str.chomp
  end

  def self.clear!
    @@finder = nil
  end

  def self.logger_debug(str)
    @logger ||= Logger.new(STDOUT)

    @logger.debug str
  end
end