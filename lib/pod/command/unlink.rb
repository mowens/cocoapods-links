require 'pod/links'

module Pod
  class Command
    class Unlink < Command
      self.summary = 'Remove pod links'
      self.description = <<-DESC
        The unlink functionality allows developers to remove reference to their local pods
        when they are finished testing

        Using 'pod unlink' in a project folder will remove the global link.
        
        Using 'pod unlink <name>' will remove the link to the <name> developement pod
        and install the <name> pod configured in the Podfile

        This allows to easily remove developement pod references
      DESC

      self.arguments = [
        CLAide::Argument.new('POD_NAME', false)
      ]

      def initialize(argv)
        @pod = argv.shift_argument()
        super
      end

      #
      # if no pod is given from the command line then we will unregister the pod from the
      # registered links
      #
      # if a pod name is given from the command line then we will unlink the given pod from
      # the project
      #
      def run 
        unless @pod.nil?
          Pod::Command::Links.unlink @pod
        else
          Pod::Command::Links.unregister
        end
      end
    end
  end
end
