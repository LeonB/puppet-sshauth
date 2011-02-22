# sshauth::key

# Declare keys.  The approach here is just to define a bunch of
# virtual resources, representing key files on the keymaster, client,
# and server.  The virtual keys are then realized by
# ssh::auth::{keymaster,client,server}, respectively.  The reason for
# doing things that way is that it makes ssh::auth::key into a "one
# stop shop" where users can declare their keys with all of their
# parameters, whether those parameters apply to the keymaster, server,
# or client.  The real work of creating, installing, and removing keys
# is done in the private definitions called by the virtual resources:
# ssh_auth_key_{master,server,client}.

define sshauth::key ($ensure = "present", $filename = "", $force = false, $group = "puppet", $home = "", $keytype = "rsa", $length = 2048, $maxdays = "", $mindate = "", $options = "", $user = "") {
	sshauth::key::namecheck { "${title}-title": parm => "title", value => $title }

	# apply defaults
	$_filename = $filename ? { "" => "id_${keytype}", default => $filename }
	$_length = $keytype ? { "rsa" => $length, "dsa" => 1024 }
	$_user = $user ? {
		""      => regsubst($title, '^([^@]*)@?.*$', '\1'),
		default => $user,
	}
	$_home = $home ? { "" => "/home/$_user",  default => $home }

	sshauth::key::namecheck { "${title}-filename": parm => "filename", value => $_filename }

	@sshauth::key::master { $title:
		ensure  => $ensure,
		force   => $force,
		keytype => $keytype,
		length  => $_length,
		maxdays => $maxdays,
		mindate => $mindate
	}

	@sshauth::key::client { $title:
		ensure   => $ensure,
		filename => $_filename,
		group    => $group,
		home     => $_home,
		user     => $_user
	}

	@sshauth::key::server { $title:
		ensure  => $ensure,
		group   => $group,
		home    => $_home,
		options => $options,
		user    => $_user
	}
}