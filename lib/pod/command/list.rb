require 'pod/links'

module Pod
  class Command
    class List
      class Links < List

        self.summary = 'List links'
        self.description = <<-DESC
          List the registered links
        DESC

        def self.options
          [[
            '--linked', 'List pods linked in the current project'
          ]].concat(super)
        end

        def initialize(argv)
          @linked = argv.flag?('linked')
          super
        end

        def run
          Pod::Command::Links.list @linked
        end
      end
    end
  end
end
