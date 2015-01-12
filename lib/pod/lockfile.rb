require 'pod/links'

#
# Logic:
# Override of the Lockfile generation to filter out linked pods in favor of their previously
# installed state (e.g. the state reflected from the Podfile). This is somewhat brittle as it
# depends on the format of the Lockfile hash contents. If the format changes, then this will also
# need to be changed. It would be far better to integrate the link filtering elsewhere but this 
# works "for now"
# 

module Pod
  class Lockfile

    PODFILE_LOCK = "Podfile.lock"

    alias_method :real_write_to_disk, :write_to_disk

    #
    # Hook the Podfile.lock file generation to allow us to filter out the links added to the
    # Podfile.lock. The logic here is to replace the new Podfile.lock link content with what existed
    # before the link was added. Currently, this is called for both Podfile.lock and Manifest.lock
    # file so we only want to alter the Podfile.lock
    # 
    # @param path path to write the .lock file to
    # 
    def write_to_disk(path)
      
      # code here mimics the original method but with link filtering
      filename = File.basename(path)
      path.dirname.mkpath unless path.dirname.exist?
      yaml = to_link_yaml
      File.open(path, 'w') { |f| f.write(yaml) }
      self.defined_in_file = path
    end

    #
    # Will create pretty print YAML stringfrom the links hash that is to be dumped to a Podfile.lock
    # 
    # This code is identical to `to_yaml` except we pass the `to_link_hash` instead of the `to_hash`
    # 
    # @returns the YAML string content to dump to a Podfile.lock without link content
    # 
    def to_link_yaml
      keys_hint = [
        'PODS',
        'DEPENDENCIES',
        'EXTERNAL SOURCES',
        'CHECKOUT OPTIONS',
        'SPEC CHECKSUMS',
        'COCOAPODS',
      ]
      YAMLHelper.convert_hash(to_link_hash, keys_hint, "\n\n")
    end

    #
    # Will get the Podfile.lock contents hash after replacing the linked content with its previous
    # Podfile.lock information keeping the Podfile and Podfile.lock in sync and clear of any link
    # data
    # 
    # @returns hash that is to be dumped to the Podfile.lock file without link content
    # 
    def to_link_hash

      # retrieve the lock contents with links
      after_hash = to_hash

      unless File.exists?(PODFILE_LOCK)
        return after_hash
      end

      # retrieve the lock content before the links
      before_hash = YAML.load(File.read(PODFILE_LOCK))

      # retrieve installed links
      links = Pod::Command::Links.installed_links

      #
      # Logic:
      # Here we will replace anything that changed in the contents that will be dumped in the
      # Podfile.lock due to links with the data that previously exists in the Podfile.lock. This
      # allows the Podfile.lock with the dependency trees to remain unchanged when linking
      # developement pods. The Podfile.lock contains several keys, but we only need to alter the
      # following:
      # 
      #  - PODS
      #  - DEPENDENCIES
      #  - EXTERNAL SOURCES
      #  - CHECKOUT OPTIONS
      #  - SPEC CHECKSUMS
      # 
      after_hash['PODS'] = 
        merge_pods links, before_hash['PODS'], after_hash['PODS'] 
      
      after_hash['DEPENDENCIES'] = 
        merge_dependencies links, before_hash['DEPENDENCIES'], after_hash['DEPENDENCIES']

      after_hash['EXTERNAL SOURCES'] = 
        merge_hashes links, before_hash['EXTERNAL SOURCES'], after_hash['EXTERNAL SOURCES']

      after_hash['CHECKOUT OPTIONS'] = 
        merge_hashes links, before_hash['CHECKOUT OPTIONS'], after_hash['CHECKOUT OPTIONS']

      after_hash['SPEC CHECKSUMS'] = 
        merge_hashes links, before_hash['SPEC CHECKSUMS'], after_hash['SPEC CHECKSUMS']

      return after_hash
    end

    def merge_pods(links, before, after)
      links.each do |link|
        before_index = find_pod_index before, link
        after_index = find_pod_index after, link
        unless before_index.nil? || after_index.nil?
          
          # get previous value
          after_value = after[after_index]

          # update new value
          after[after_index] = before[before_index]

          # iterate and update all dependencies of previous value
          if after_value.is_a?(Hash)

            # clean all deps that may have been added as new deps
            after_value[after_value.keys[0]].each do |key|
              # key: CocoaLumberjack/Core or CocoaLumberjack/Extensions (= 1.9.2)
              key_desc = key.split(" (", 2)[0]

              inner_after_index = find_pod_index after, key_desc
              inner_before_index = find_pod_index before, key_desc
              
              unless inner_before_index.nil? && inner_after_index.nil?
                after[inner_after_index] = before[inner_before_index]
              else 
                # if it was removed in the new deps
                unless before_index.nil?
                  after.insert(before_index, before[before_index])
                end
              end   
            end
          end
        end
      end
      return after
    end

    #
    # Will merge the DEPENDENCIES of the Podfile.lock before a link and after a link
    # 
    # @param links the installed links
    # @param before the DEPENDENCIES in the Podfile.lock before the link occurs
    # @param after the DEPENDENCIES after the link (includes new link that we want to filter out)
    # 
    # @returns the merged DEPENDENCIES replacing any links that were added with their previous value
    #
    def merge_dependencies(links, before, after)
      links.each do |link|
        before_index = find_dependency_index before, link
        after_index = find_dependency_index after, link
        unless before_index.nil? || after_index.nil?
          after[after_index] = before[before_index]
        end
      end
      return after
    end

    #
    # Will merge the hashes of the Podfile.lock before a link and after a link
    # 
    # @param links the installed links
    # @param before the hash in the Podfile.lock before the link occurs
    # @param after the hash after the link (includes new link that we want to filter out)
    # 
    # @returns the merged hash replacing any links that were added with their previous value
    # 
    def merge_hashes(links, before, after)
      links.each do |link|
        if before.has_key?(link)
          after[link] = before[link]
        else
          if after.has_key?(link)
            after.delete(link)
          end
        end
      end
      return after
    end

  private

    #
    # Find the index in the pod array based on the link name. The pod array
    # also contains version/path information so we need to massage the pod value 
    # for comparison. Pods are in the following format:
    # 
    # Name (requirements)
    # 
    # Example:
    # Alamofire (= 1.1.3)
    # 
    # @param pods the array to search
    # @param name the name of the pod to find
    # 
    # NOTE: the pods in the array can be strings or hashes, so we will check for both
    # 
    # @return the index of nil
    # 
    def find_pod_index(pods, name)
      pods.index { |pod|
        desc = pod
        if pod.is_a?(Hash)
          desc = pod.keys[0]
        end
        desc.split(" (", 2)[0] == name
      }
    end

    #
    # Find the index in the dependency array based on the link name. The dependency array
    # also contains version/path information so we need to massage the dependency value 
    # for comparison. Dependencies are in the following format:
    # 
    # Name (requirements)
    # 
    # Example:
    # Alamofire (= 1.1.3)
    # Quick (from `https://github.com/Quick/Quick`, tag `v0.2.2`)
    # 
    # @param dependencies the array to search
    # @param name the name of the dependency to find
    # 
    # @returns the index of nil
    # 
    def find_dependency_index(dependencies, name)
      dependencies.index { |dependency| 
        dependency.split(" (", 2)[0] == name
      }
    end
  end
end
