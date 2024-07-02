require "json"

module Collab
  module JS
    @queue = Queue.new
    @queue_initialized = false
    @queue_initialization_mutex = Mutex.new

    class <<self
      def queue
        initialize_queue unless @queue_initialized
        @queue
      end

      # Calls the block given with a JS process acquired from the queue
      # Will block until a JS process is available
      def with_js
        js = queue.pop
        yield js
      ensure
        queue << js
      end

      def call(name, data = nil, schema_name = nil)
        req = {name: name, data: data, schemaPackage: ::Collab.config.schema_package}
        req[:schemaName] = schema_name if schema_name
        with_js { |js| js.call(JSON.generate(req)) }
      end
      
      def apply_commit(document, commit, pos: nil, map_steps_through:, schema_name:)
        call("applyCommit", {doc: document, commit: commit, mapStepsThrough: map_steps_through, pos: pos},schema_name)
      end

      def html_to_document(html, schema_name:)
        call("htmlToDoc", html, schema_name)
      end

      def document_to_html(document, schema_name:)
        call("docToHtml", document, schema_name)
      end

      def map_through(steps:, pos:)
        call("mapThru", {steps: steps, pos: pos})
      end

      private 
      # Thread-safe initialization of the NodeJS process queue
      def initialize_queue
        @queue_initialization_mutex.synchronize do
          unless @queue_initialized
            ::Collab.config.num_js_processes.times { @queue << ::Collab::JS::JSProcess.new }
            @queue_initialized = true
          end
        end
      end
    end

    class JSProcess
      def initialize
         @node = if defined?(Rails)
                   Dir.chdir(Rails.root) { open_node }
                 else
                   open_node
                 end
      end

      def call(req)
        @node.puts(req)
        res = JSON.parse(@node.gets)
        raise ::Collab::JS::JSRuntimeError.new(res["error"]) if res["error"]
        res["result"]
      end

      private
      def open_node
        IO.popen(["node", "-e", "require('@pmcp/authority/dist/rpc')"], "r+")
      end
    end

    class JSRuntimeError < StandardError
      def initialize(data)
        @js_backtrace = data["stack"].split("\n").map{|f| "JavaScript #{f.strip}"} if data["stack"]

        super(data["name"] + ": " + data["message"])
      end

      def backtrace
        return unless  val = super
        
        if @js_backtrace
          @js_backtrace + val
        else
          val
        end
      end
    end
  end
end
