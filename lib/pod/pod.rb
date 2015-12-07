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
          Pod::Command::Links.print "Using link '#{name}' > #{link['path']}"
          real_pod(name, :path => link['path'], &block)
        else
          real_pod(name, *requirements, &block)
        end
      end
    end
  end
end
