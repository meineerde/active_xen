module ActiveXen
  module Models
    class Host < ActiveXen::Base
      self.xen_class = 'host'

      HOST_ALLOWED_OPERATIONS = [
        'provision',  # Indicates this host is able to provision another VM
        'evacuate',   # Indicates this host is evacuating
        'shutdown',   # Indicates this host is in the process of shutting itself down
        'reboot',     # Indicates this host is in the process of rebooting
        'power_on',   # Indicates this host is in the process of being powered on
        'vm_start',   # This host is starting a VM
        'vm_resume',  # This host is resuming a VM
        'vm_migrate'  # This host is the migration target of a VM
      ]

      attribute :address
      read_only_attribute :allowed_operations

      read_only_attribute :API_version_major, :type => :integer
      read_only_attribute :API_version_minor, :type => :integer
      read_only_attribute :API_version_vendor
      read_only_attribute :API_version_vendor_implementation

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

      read_only_attribute :boot_free_mem, :type => :integer
      read_only_attribute :capabilities
      read_only_attribute :cpu_configuration
      read_only_attribute :cpu_info

      has_one :crash_dump_sr, :class_name => 'SR'
      has_many :crashdumps, :class_name => 'HostCrashdump', :read_only => true

      read_only_attribute :current_operations
      read_only_attribute :edition
      read_only_attribute :enabled, :type => :boolean

      read_only_attribute :external_auth_configuration
      read_only_attribute :external_auth_service_name
      read_only_attribute :external_auth_type

      read_only_attribute :ha_network_peers
      read_only_attribute :ha_statefiles

      has_many :host_CPUs, :class_name => 'HostCPU', :read_only => true

      attribute :hostname

      read_only_attribute :license_params
      read_only_attribute :license_server

      has_one :local_cache_sr, :class_name => 'SR', :read_only => true



    end
  end
end