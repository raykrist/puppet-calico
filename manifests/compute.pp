# == Class: calico
#
class calico::compute (
  $bird_template           = $calico::compute_bird_template,
  $felix_enable            = $calico::felix_enable,
  $felix_template          = $calico::felix_template,
  $metadata_service_enable = $calico::compute_metadata_service_enable,
  $manage_bird_config      = $calico::compute_manage_bird_config,
  $manage_dhcp_agent       = $calico::compute_manage_dhcp_agent,
  $manage_metadata_service = $calico::compute_manage_metadata_service,
  $manage_peers            = $calico::compute_manage_peers,
  $manage_qemu_settings    = $calico::compute_manage_qemu_settings,
  $peer_defaults           = {},
  $peer_template           = $calico::compute_peer_template,
  $peers                   = {},
  $router_id               = $calico::router_id,
) {

  validate_bool($manage_dhcp_agent)
  validate_bool($manage_peers)
  validate_bool($manage_qemu_settings)

  if $manage_dhcp_agent { include 'neutron::agents::dhcp' }
  if $manage_qemu_settings { include 'calico::compute::qemu' }

  package { $calico::compute_package:
    ensure => installed,
  }

  file { $calico::felix_conf:
    ensure  => present,
    content => template($felix_template)
  }

  service { $calico::felix_service:
    ensure => running,
    enable => $felix_enable,
  }

  Package[$calico::compute_package] ->
  File[$calico::felix_conf] ~>
  Service[$calico::felix_service]

  if $manage_metadata_service {
    package { $calico::compute_metadata_package:
       ensure => installed,
    }
    service { $calico::compute_metadata_service:
      ensure => running,
      enable => $calico::compute_metadata_service_enable,
    }
    Package[$calico::compute_metadata_package] ~>
    Service[$calico::compute_metadata_service]
  }

  if $manage_bird_config {
    contain 'calico::bird'
  }

  if $manage_peers {
    contain 'calico::bird'
    $peer_resources = keys($peers)
    calico::compute::peers { $peer_resources:
      peer_defaults => $peer_defaults,
      peer_template => $peer_template,
      peers         => $peers,
    }
  }

}
