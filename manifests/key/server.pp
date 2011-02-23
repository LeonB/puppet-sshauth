# sshauth::key::server
#
# Install a public key into a server user's authorized_keys(5) file.
# This definition is private, i.e. it is not intended to be called directly by users.

define sshauth::key::server ($ensure, $group, $home, $options, $user) {
	include sshauth::params
	
	# on the keymaster:
	$key_src_dir = "${sshauth::params::keymaster_storage}/${name}"
	$key_src_file = "${key_src_dir}/key.pub"

	# on the server:
	$key_tgt_file = "${home}/.ssh/authorized_keys"

	File {
		owner   => $user,
		group   => $group,
		require => User[$user],
		mode    => 600,
	}

	Ssh_authorized_key {
		user   => $user,
		target => $key_tgt_file,
	}

	if $ensure == "absent" {
		ssh_authorized_key { $name: ensure => "absent" }
	} else {
		$key_src_content = file($key_src_file, "/dev/null")
		
		if ! $key_src_content {
			notify { "Public key file $key_src_file for key $name not found on keymaster; skipping ensure => present": }
		} else {
			if $ensure == "present" and $key_src_content !~ /^(ssh-...) ([^ ]*)/ {
				err("Can't parse public key file $key_src_file")
				notify { "Can't parse public key file $key_src_file for key $name on the keymaster: skipping ensure => $ensure": }
			} else {
				$keytype = $1
				$modulus = $2
				
				ssh_authorized_key { $name:
					ensure  => "present",
					type    => $keytype,
					key     => $modulus,
					options => $options ? { "" => undef, default => $options },
				}
			}
		}
	}
}
