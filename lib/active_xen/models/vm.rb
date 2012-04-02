module ActiveXen
  module Models
    class VM < ActiveXen::Base
      self.xen_class = 'VM'

      ON_CRASH_BEHAVIOUR = [
        'destroy', # destroy the VM state
        'coredump_and_destroy', # record a coredump  anf then destroy the VM state
        'restart', # restart the VM
        'coredump_and_restart', # record a coredump and then restart the VM
        'preserve', # leave the crashed VM paused
        'rename_restart' #rename the crashed VM and start a new copy
      ]

      ON_NORMAL_EXIT = [
        'destroy', # destroy the VM state,
        'restart' # restart the VM
      ]

      VM_OPERATIONS = [
        'snapshot', # refers to the operation "snapshot"
        'clone', # refers to the operation "clone"
        'copy', # refers to the operation "copy"
        'create_template', # refers to the operation "create_template"
        'revert', # refers to the operation "revert"
        'checkpoint', # refers to the operation "checkpoint"
        'snapshot_with_quiesce', # refers to the operation "snapshot_with_quiesce"
        'provision', # refers to the operation "provision"
        'start', # refers to the operation "start"
        'start_on', # refers to the operation "start_on"
        'pause', # refers to the operation "pause"
        'unpause', # refers to the operation "unpause"
        'clean_shutdown', # refers to the operation "clean_shutdown"
        'clean_reboot', # refers to the operation "clean_reboot"
        'hard_shutdown', # refers to the operation "hard_shutdown"
        'power_state_reset', # refers to the operation "power_state_reset"
        'hard_reboot', # refers to the operation "hard_reboot"
        'suspend', # refers to the operation "suspend"
        'csvm', # refers to the operation "csvm"
        'resume', # refers to the operation "resume"
        'resume_on', # refers to the operation "resume_on"
        'pool_migrate', # refers to the operation "pool_migrate"
        'migrate', # refers to the operation "migrate"
        'get_boot_record', # refers to the operation "get_boot_record"
        'send_sysrq', # refers to the operation "send_sysrq"
        'send_trigger', # refers to the operation "send_trigger"
        'changing_memory_live', # Changing the memory settings
        'awaiting_memory_live', # Waiting for the memory settings to change
        'changing_dynamic_range', # Changing the memory dynamic range
        'changing_static_range', # Changing the memory static range
        'changing_memory_limits', # Changing the memory limits
        'get_cooperative', # Querying the co-operativeness of the VM
        'changing_shadow_memory', # Changing the shadow memory for a halted VM.
        'changing_shadow_memory_live', # Changing the shadow memory for a running VM.
        'changing_VCPUs', # Changing VCPU settings for a halted VM.
        'changing_VCPUs_live', # Changing VCPU settings for a running VM.
        'assert_operation_valid',
        'data_source_op', # Add, remove, query or list data sources
        'update_allowed_operations',
        'make_into_template', # Turning this VM into a template
        'import', # importing a VM from a network stream
        'export', # exporting a VM to a network stream
        'metadata_export', # exporting VM metadata to a network stream
        'reverting', # Reverting the VM to a previous snapshotted state
        'destroy' # refers to the act of uninstalling the VM
      ]

      VM_POWER_STATE = [
        'Halted',
        'Paused',
        'Running',
        'Suspended'
      ]

      has_one :affinity, :class_name => 'Host'
      validates_presence_of :affinity
      has_one :resident_on, :class_name => 'Host', :read_only => true
      has_one :scheduled_to_be_resident_on, :class_name => 'Host', :read_only => true

      has_many :children, :class_name => 'Host', :read_only => true
      has_many :consoles, :class_name => 'Console', :read_only => true
      has_many :crash_dumps, :class_name => 'CrashDump', :read_only => true

      has_many :guest_metrics, :class => 'VMGuestMetrics', :read_only => true
      has_many :metrics, :class => 'Metrics', :read_only => true

      has_one :parent, :class => 'VM', :read_only => true
      has_one :protection_policy, :class => 'VMPP', :read_only => true

      has_one :suspend_vdi, :class => 'VDI', :read_only => true
      has_many :VBDs, :class => 'VBD', :read_only => true
      has_many :VIFs, :class => 'VIF', :read_only => true
      has_many :VTPMs, :class => 'VTPM', :read_only => true

      attribute :actions_after_crash
      validates_inclusion_of :actions_after_crash, :in => ON_CRASH_BEHAVIOUR

      attribute :actions_after_reboot
      validates_inclusion_of :actions_after_reboot, :in => ON_NORMAL_EXIT

      attribute :actions_after_shutdown
      validates_inclusion_of :actions_after_shutdown, :in => ON_NORMAL_EXIT

      read_only_attribute :allowed_operations # VM_OPERATIONS
      read_only_attribute :current_operations # Hash: String => VM_OPERATIONS
                                              # TODO: validate the format

      attribute :blocked_operations # Hash: VM_OPERATIONS => String
                                    # TODO: validate the format

      read_only_attribute :bios_strings

      # TODO: handle create_new_blob and fully wrap blob handling
      read_only_attribute :blobs do
        values = read_attribute('blobs') || []
        return values unless values.any?{ |v| v.is_a?(String) }

        values = values.inject({}) do |blobs, (name, ref)|
          blobs[name] = model_instance(ref, 'Blob')
          blobs
        end

        record['blobs'] = values
      end
      # TODO validate blobs

      read_only_attribute :domarch
      read_only_attribute :domid

      attribute :ha_always_run do
        get { read_attribute('ha_always_run') == 'true' }
        save { proxy.set_ha_always_run(ha_always_run) }
      end
      attribute :ha_restart_priority do
        save { proxy.set_ha_restart_priority(ha_restart_priority) }
      end

      attribute :HVM_boot_params do
        get { super() || {} }
      end
      attribute :HVM_boot_policy do
        get { super() || "" }
      end
      attribute :HVM_shadow_multiplier, :type => :float, :default => 1.0 do
        save { proxy.set_HVM_shadow_multiplier(hvm_shadow_multiplier) }
      end

      attribute :is_a_template, :type => :boolean
      read_only_attribute :is_a_snapshot
      read_only_attribute :is_control_domain
      read_only_attribute :is_snapshot_from_vmpp

      read_only_attribute :last_boot_CPU_flags
      read_only_attribute :last_booted_record

      memory_attrs = %w[memory_static_min memory_static_max memory_dynamic_min memory_dynamic_max]
      memory_attrs.each do |memory_attr|
        attribute memory_attr do |accessor|
          accessor.update do
            limits = memory_attrs.collect{ |m| send(m) }
            proxy.set_memory_limits(*limits)
            memory_attrs.each{ |m| changed_attributes.delete(m) }
          end
        end
      end

      read_only_attribute :memory_overhead

      attribute :name_description, :default => ""
      attribute :name_label, :default => ""

      attribute :other_config, :default => {}
      attribute :PCI_bus, :default => ""
      attribute :platform, :default => {}

      read_only_attribute :power_state # VM_POWER_STATE

      attribute :protection_policy do
        save { proxy.set_protection_policy(model_instance(protection_policy, 'VMPP').to_ref) }
      end

      attribute :PV_args, :default => ""
      attribute :PV_bootloader, :default => "pygrub"
      attribute :PV_bootloader_args, :default => ""
      attribute :PV_kernel, :default => ""
      attribute :PV_legacy_args, :default => ""
      attribute :PV_ramdisk, :default => ""

      attribute :recommendations, :default => ""

      read_only_attribute :snapshot_info
      read_only_attribute :snapshot_metadata
      read_only_attribute :snapshot_time

      read_only_attribute :transportable_snapshot_id

      has_one :snapshot_of, :class_name => 'VM', :read_only => true
      has_many :snapshots, :class_name => 'VM', :read_only => true

      attribute :tags # Array of Strings
      attribute :user_version, :type => :integer
      read_only_attribute :version, :type => :integer, :default => 0

      attribute :VCPUs_at_startup, :type => :integer do
        update { proxy.set_VCPUs_at_startup(vcpus_at_startup) }
      end
      attribute :VCPUs_max, :type => :integer do
        update { proxy.set_VCPUs_max(vcpus_max) }
      end

      attribute :VCPUs_params, :default => {} # Hash String => String
      attribute :xenstore_data, :default => {} # Hash: String => String

      # Add the given key-value pair to VM.VCPUs_params, and apply that value on the running VM
      def add_to_VCPUs_params_live!(key, value)
        proxy.add_to_VCPUs_params_live(key, value)
        nil
      end

      # Check if the VM is considered agile, e.g. it is not tied to a resource local to a host
      # If the VM is not agile, it returns false or raises an exception if +raise_error+ is true
      def agile?(raise_error=false)
        proxy.assert_agile
        true
      rescue ActiveXen::GenericError
        raise_error ? raise : false
      end
      alias :assert_agile :agile?


      # Check if the VM can boot on the given +host+.
      # If the VM can not boot on this host, it returns false or raises an exception
      # if +raise_error+ is true
      def can_boot_here?(host, raise_error=false)
        proxy.assert_can_boot_here(model_instance(host, 'Host').to_ref)
        true
      rescue ActiveXen::GenericError
        raise_error ? raise : false
      end
      alias :assert_can_boot_here :can_boot_here?

      # Check to see whether this +operation+ is acceptable in the current state of the system.
      # +operation+ must be one of +VM_OPERATIONS+.
      # If the operation is invalid for some reason, it returns false or raises an exception
      # if +raise_error+ is true.
      def operation_valid?(operation, raise_error=false)
        proxy.assert_operation_valid(operation)
        true
      rescue ActiveXen::GenericError
        raise_error ? raise : false
      end
      alias :assert_operation_valid :operation_valid?

      # Checkpoints the VM, making a new VM. Checkpoint automatically exploits the
      # capabilities of the underlying storage repository in which the VM's disk images are
      # stored (e.g. Copy on Write) and saves the memory image as well.
      def checkpoint!(new_name)
        proxy.checkpoint(new_name)
        nil
      end

      # Attempt to cleanly reboot the specified VM.
      # Note: this may not be supported e.g. if a guest agent is not installed.
      #
      # This can only be called when the VM is in the Running state.
      def clean_reboot!
        proxy.clean_reboot
        nil
      end

      # Attempt to cleanly shutdown the specified VM.
      # Note: this may not be supported e.g. if a guest agent is not installed.
      #
      # This can only be called when the VM is in the Running state.
      def clean_shutdown!
        proxy.clean_shutdown
        nil
      end

      # Clones this VM, making a new VM. Clone automatically exploits the
      # capabilities of the underlying storage repository in which the VM's
      # disk images are stored (e.g. Copy on Write).
      # The new VM is returned.
      #
      # This function can only be called when this VM is in the Halted State.
      def clone!(new_name)
        vm_ref = proxy.clone(new_name)
        model_instance(vm_ref, 'VM')
      end

      # Computes the virtualization memory overhead of a VM.
      def compute_memory_overhead()
        proxy.compute_memory_overhead
      end

      # Copied the VM, making a new VM. Unlike clone, copy does not exploits
      # the capabilities of the underlying storage repository in which the
      # VM's disk images are stored. Instead, copy guarantees that the disk
      # images of the newly created VM will be 'full disks' - i.e. not part
      # of a CoW chain.
      #
      # This function can only be called when the VM is in the Halted State.
      def copy!(new_name, sr=nil)
        sr_ref = sr ? model_instance(sr, 'SR').to_ref : ""

        vm_ref = proxy.copy(new_name, sr)
        model_instance(vm_ref, 'VM')
      end

      # Copy the BIOS strings from the given host to this VM
      def copy_bios_strings!(host)
        host_ref = model_instance(host, 'Host').to_ref
        proxy.copy_bios_strings(host_ref)
      end

      # Forget the recorded statistics related to the specified data source
      def forget_data_source_archives!(data_source)
        proxy.forget_data_source_archives(data_source)
        nil
      end

      # Returns a list of the allowed values that a VBD device field can take
      def allowed_VBD_devices
        @allowed_VBD_devices ||= proxy.get_allowed_VBD_devices
      end
      alias :get_allowed_VBD_devices :allowed_VBD_devices

      # Returns a list of the allowed values that a VIF device field can take
      def allowed_VIF_devices
        @allowed_VIF_devices ||= proxy.get_allowed_VIF_devices
      end
      alias :get_allowed_VIF_devices :allowed_VIF_devices

      # Returns a record describing the VM's dynamic state, initialised
      # when the VM boots and updated to reflect runtime configuration
      # changes e.g. CPU hotplug
      def boot_record
        @boot_record ||= begin
          vm_ref ||= proxy.get_boot_record
          model_instance(vm_ref, 'VM')
        end
      end
      alias :get_boot_record :boot_record

      # Return true if the VM is currently 'co-operative' i.e. is expected
      # to reach a balloon target and actually has done
      def cooperative?
        @get_cooperative ||= (proxy.get_cooperative == 'true')
      end
      alias :get_cooperative :cooperative?

      # Return the list of hosts on which this VM may run.
      def possible_hosts
        @possible_hosts ||= proxy.get_possible_hosts.collect do |ref|
          model_instance(ref, 'Host')
        end
      end
      alias :get_possible_hosts :possible_hosts

      # Stop executing the VM without attempting a clean shutdown and
      # immediately restart the VM.
      def hard_reboot!
        proxy.hard_reboot
      end

      # Stop executing the specified VM without attempting a clean shutdown.
      def hard_shutdown!
        proxy.hard_shutdown
      end

      # Returns the maximum amount of guest memory which will fit, together
      # with overheads, in the supplied amount of physical memory
      # (the maximum memory_static_max).
      #
      # If +approximate+ is false then an exact calculation is performed using
      # the VM's current settings. If +approximate+ is true (the default)
      # then a more conservative approximation is used
      def maximize_memory(total, approximate=true)
        @maximize_memory ||= proxy.maximize_memory(approximate)
      end

      # Pause the VM. This can only be called when the VM is in the Running state.
      def pause!
        proxy.pause
      end

      # Migrate the VM to another Host. This can only be called when the
      # VM is in the Running state.
      def pool_migrate!(host, options={})
        host = model_instance(host, 'Host')
        options = options.inject({}) { |o, (k, v)| o[k.to_s] = v.to_s; o }

        proxy.pool_migrate(host, options)
      end

      # Reset the power-state of the VM to halted in the database only.
      #
      # This is used to recover from slave failures in pooling scenarios
      # by resetting the power-states of VMs running on dead slaves to halted.
      #
      # This is a potentially dangerous operation; use with care!
      def power_state_reset!
        proxy.power_state_reset
      end

      # Inspects the disk configuration contained within the VM's other_config,
      # creates VDIs and VBDs and then executes any applicable post-install script.
      #
      # If creating a VM, you first have to actually create / save it before
      # calling provision!
      def provision!
        proxy.provision
      end

      # Query the latest value of the specified data source,
      # averaged over the last 5 seconds
      def query_data_source(data_source)
        proxy.query_data_source(data_source)
      end

      # Awaken this VM and resume it.
      #
      # This can only be called when the VM is in the Suspended state.
      def resume!(start_paused=false, force=false)
        proxy.resume((!!start_paused).to_s, (!!force).to_s)
        nil
      end

      # Awaken the specified VM and resume it on a particular Host.
      #
      # This can only be called when the VM is in the Suspended state.
      def resume_on!(host, start_paused=false, force=false)
        host = model_instance(host, 'Host')
        proxy.resume_on(host, (!!start_paused).to_s, (!!force).to_s)
        nil
      end

      def retrieve_wlb_recommendations
        result = proxy.retrieve_wlb_recommendations

        # and now do something with it...
        raise NotImplementedError
      end

      # Reverts the specified VM to a previous state.
      # Call this on the VM representing the snapshot
      def revert!
        proxy.revert
        nil
      end

      # Send the given key as a sysrq to this VM.
      # The key is specified as a single character (a String of length 1).
      #
      # This can only be called when the VM is in the Running state.
      def send_sysrq!(key)
        proxy.send_sysrq(key)
        nil
      end

      # Send the given named trigger to this VM.
      #
      # This can only be called when the VM is in the Running state.
      def send_trigger!(trigger)
        proxy.send_trigger(trigger)
        nil
      end

      # Set the number of VCPUs for a running VM
      def set_vcpus_number_live!(number_of_vcpus)
        proxy.set_VCPUs_number_live(number_of_vcpus)
        nil
      end

      # Snapshots the specified VM, making a new VM.
      # Snapshot automatically exploits the capabilities of the underlying storage repository
      # in which the VM's disk images are stored (e.g. Copy on Write).
      def snapshot!(new_name)
        vm_ref = proxy.snapshot(new_name)
        model_instance(vm_ref, 'VM')
      end

      # Snapshots the specified VM with quiesce, making a new VM.
      # Snapshot automatically exploits the capabilities of the underlying storage repository
      # in which the VM's disk images are stored (e.g. Copy on Write).
      def snapshot_with_quiesce(new_name)
        vm_ref = proxy.snapshot_with_quiesce(new_name)
        model_instance(vm_ref, 'VM')
      end

      # Start the VM.
      #
      # This function can only be called with the VM is in the Halted State.
      def start!(start_paused=false, force=false)
        proxy.start((!!start_paused).to_s, (!!force).to_s)
        nil
      end

      # Start the VM on a particular host.
      #
      # This function can only be called with the VM is in the Halted State.
      def start_on!(host, start_paused=false, force=false)
        host_ref = model_instance(host, 'Host').to_ref
        proxy.start_on(host_ref, (!!start_paused).to_s, (!!force).to_s)
        nil
      end

      # Suspend this VM to disk.
      #
      # This can only be called when the VM is in the Running state.
      def suspend!
        proxy.suspend
        nil
      end

      # Resume this VM.
      #
      # This can only be called when the VM is in the Paused state.
      def unpause!
        proxy.unpause
        nil
      end

      # Recomputes the list of acceptable operations
      def update_allowed_operations!
        proxy.update_allowed_operations
        nil
      end
    end
  end
end