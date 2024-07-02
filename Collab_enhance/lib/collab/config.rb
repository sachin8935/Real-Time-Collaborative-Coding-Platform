module Collab
  @config_mutex = Mutex.new

  def self.config
    if block_given?
      @config_mutex.synchronize do
        @config ||= ::Collab::Config.new
        raise "[Collab] Tried to configure gem after first use" if @config.frozen?
        yield @config
      end
    else
      raise "[Collab] Missing configuration - Have you run `rails g collab:install` yet?" unless @config
      @config.freeze # really weird stuff could happen if the config changes after first use, so freeze config
    end
  end

  class Config
    attr_accessor :base_record,
                  :channel,
                  :commit_model,
                  :document_model,
                  :max_commit_history_length,
                  :num_js_processes,
                  :schema_package,
                  :tracked_position_model

    def initialize
      self.document_model = "Collab::Models::Document"
      self.commit_model = "Collab::Models::Commit"
      self.tracked_position_model = "Collab::Models::TrackedPosition"
    end
  end
end
