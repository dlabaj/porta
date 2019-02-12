module ResetTenantId
  extend ActiveSupport::Concern

  class Configurator
    include Singleton
    attr_reader :definitions

    def initialize
      @definitions = {}
    end

    def define(klass,  &block)
      definition = definitions[klass] ||= Definition.new(klass)
      definition.instance_exec(&block)
    end
  end

  class Definition
    attr_reader :queries
    delegate :each_value, to: :queries

    def initialize(klass)
      @klass = klass
      @queries = {}
    end

    def updates(name, options = {}, &block)
      @queries[name.to_sym] = Query.new(name, options, &block)
    end

    def [](name)
      @queries[name.to_sym]
    end
  end

  class Query
    attr_reader :collection, :name, :with

    def initialize(name, options={}, &block)
      @name = name.to_sym
      @collection = options[:collection] || @name
      @with = options[:with] || block
    end

    # Returns an object responding to #call(record)
    def update
      case @with
      when Symbol
        Proc.new do |record|
          record.update_column :tenant_id, record.public_send(@with)
        end
      else
        @with
      end
    end
  end

  class Runner
    attr_reader :klass, :definitions

    def initialize(klass, definitions)
      @klass = klass
      @definitions = definitions
    end

    def execute(name)
      query = find_query(name)
      # probably adding logging here
      return unless query
      execute_query(query)
    end

    def execute_all
      definitions[klass].each_value do |query|
        execute_query(query)
      end
    end

    def execute_query(query)
      # This can be hooked to be async :)
      collection = query.collection
      collection = case collection
                   when Proc
                     klass.instance_exec(&collection)
                   when Symbol
                     klass.public_send(collection)
                   when Array
                     collection.extends(FindEach)
                   else
                     collection
                   end

      collection.find_each(&query.update)
    end

    def find_query(name)
      definitions[klass][name.to_sym]
    end

    module FindEach
      def find_each(&block)
        defined?(super) ? super(&block) : each(&block)
      end
    end
  end

  def reset_tenant_id!(name)
    runner = ResetTenantId::Runner.new(self.class, ResetTenantId::Configurator.instance.definitions)
    query = runner.find_query(name)
    query.update.call(self) unless query
  end

  module ClassMethods

    # define_reset_tenant_id do
    #   updates(:buyers, with: :provider_account_id)
    #
    #   updates(:buyers) do |record|
    #     record.provider_account_id
    #   end
    #
    #   updates(first_3_accounts, collection: Account.find(1,2,3), with: :provider_account_id)
    #
    #   updates(:all_tags, collection: -> { ActiveRecord::Base.connection.execute("SELECT id, account_id FROM tags") }) do |record|
    #     id, account_id = record
    #     ActiveRecord::Base.connection.execute("UPDATE tags SET tenant_id = account_id WHERE id = #{id}")
    #   end
    # end
    def define_reset_tenant_id(&block)
      ResetTenantId::Configurator.instance.define(self, &block)
    end

    def reset_tenant_id!(name = nil)
      runner = ResetTenantId::Runner.new(self, ResetTenantId::Configurator.instance.definitions)
      if name
        runner.execute(name)
      else
        runner.execute_all
      end
    end
  end
end

__END__