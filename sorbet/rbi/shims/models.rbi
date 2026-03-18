# typed: true
# Model attribute and association shims for ActiveRecord models.
# These will be replaced by tapioca DSL-generated RBIs when available.

class VpnConfiguration
  sig { returns(T.nilable(String)) }
  def wg_private_key; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_private_key=(val); end

  sig { returns(T.nilable(String)) }
  def wg_public_key; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_public_key=(val); end

  sig { returns(T.nilable(String)) }
  def wg_ip_address; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_ip_address=(val); end

  sig { returns(T.nilable(String)) }
  def wg_fqdn; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_fqdn=(val); end

  sig { returns(T.nilable(String)) }
  def wg_port; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_port=(val); end

  sig { returns(T.nilable(String)) }
  def wg_ip_range; end

  sig { returns(T::Boolean) }
  def wg_ip_range_changed?; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_ip_range=(val); end

  sig { returns(T.nilable(String)) }
  def server_vpn_ip_address; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def server_vpn_ip_address=(val); end

  sig { returns(T.nilable(String)) }
  def dns_servers; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def dns_servers=(val); end

  sig { returns(T.nilable(String)) }
  def wg_interface_name; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_interface_name=(val); end

  sig { returns(T.nilable(String)) }
  def wg_keep_alive; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_keep_alive=(val); end

  sig { returns(T.nilable(String)) }
  def wg_forward_interface; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def wg_forward_interface=(val); end

  sig { returns(T.nilable(String)) }
  def wg_listen_address; end

  sig { returns(T.untyped) }
  def network_addresses; end
end

class VpnDevice
  sig { returns(T.nilable(String)) }
  def description; end

  sig { returns(T::Boolean) }
  def description?; end

  sig { returns(T.nilable(String)) }
  def public_key; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def public_key=(val); end

  sig { returns(T.nilable(String)) }
  def private_key; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def private_key=(val); end

  sig { returns(T.nilable(T::Boolean)) }
  def node; end

  sig { returns(T::Boolean) }
  def node?; end

  sig { returns(T.nilable(String)) }
  def served_networks; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def served_networks=(val); end

  sig { returns(T::Boolean) }
  def served_networks_changed?; end

  sig { returns(T.untyped) }
  def ip_allocation; end

  sig { returns(User) }
  def user; end
end

class IpAllocation
  sig { returns(T.nilable(String)) }
  def ip_address; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def ip_address=(val); end

  sig { returns(T::Boolean) }
  def allocated; end

  sig { params(val: T::Boolean).returns(T::Boolean) }
  def allocated=(val); end

  sig { returns(T.nilable(VpnDevice)) }
  def vpn_device; end

  sig { params(val: T.nilable(VpnDevice)).returns(T.nilable(VpnDevice)) }
  def vpn_device=(val); end

  sig { returns(T.untyped) }
  def self.allocated; end

  sig { returns(T.untyped) }
  def self.unallocated; end

  sig { returns(T.untyped) }
  def self.lock; end
end

class NetworkAddress
  sig { returns(T.nilable(String)) }
  def network_address; end

  sig { params(val: T.nilable(String)).returns(T.nilable(String)) }
  def network_address=(val); end

  sig { returns(T.nilable(Integer)) }
  def vpn_configuration_id; end

  sig { params(val: T.nilable(Integer)).returns(T.nilable(Integer)) }
  def vpn_configuration_id=(val); end
end

class User
  sig { returns(T.nilable(String)) }
  def email; end

  sig { returns(T.nilable(String)) }
  def name; end

  sig { returns(T.nilable(T::Boolean)) }
  def admin; end

  sig { returns(T::Boolean) }
  def admin?; end

  sig { returns(T::Boolean) }
  def active?; end

  sig { returns(T.nilable(String)) }
  def provider; end

  sig { returns(T.nilable(String)) }
  def uid; end

  sig { returns(T.nilable(String)) }
  def profile_picture_url; end

  sig { returns(T.untyped) }
  def vpn_devices; end
end

# ActiveSupport core extensions
class String
  sig { returns(T::Boolean) }
  def present?; end

  sig { returns(T::Boolean) }
  def blank?; end
end

class NilClass
  sig { returns(T::Boolean) }
  def present?; end

  sig { returns(T::Boolean) }
  def blank?; end
end

class Object
  sig { returns(T.nilable(T.self_type)) }
  def presence; end
end

class Array
  sig { returns(T::Array[T.untyped]) }
  def compact_blank; end
end
