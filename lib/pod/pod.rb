require 'pod/links'

#
# In order to support installing pods from links we want to override the pod entry point
# in the pod spec so we can lookup a link prior to installing the pod
#
module Pod
  class Podfile
    module DSL
      alias_method :real_pod, :pod
      def pod(name = nil, *requirements, &block)
        #
        # Logic:
        # Lookup a link for the given pod name. If a link exists then the pod will be installed
        # via the link instead of the provided requirements (e.g. it will setup local pod development
        # for the link). If the link does not exist, then the pod will be installed normally
        #

        # handle subspec link
        linked_name = name
        if name.include? "/"
          linked_name = name.split("/")[0]
        end
        link = Pod::Command::Links.get_link(linked_name)
        unless link.nil?
          message = "Using link '#{name}' > #{link['path']}"
          new_requirements = [:path => link['path']]

          # Parsing inspired from CocoaPods's `parse_subspecs` method
          # https://github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/podfile/target_definition.rb#L1152
          options = requirements.last
          if options.is_a?(Hash) && options.has_key?(:subspecs)
            message += " with subspecs: #{options[:subspecs]}"
            new_requirements.append(:subspecs => options[:subspecs])
          end

          Pod::Command::Links.print message
          real_pod(name, *new_requirements, &block)
        else
          real_pod(name, *requirements, &block)
        end
      end
    end
  end
end
