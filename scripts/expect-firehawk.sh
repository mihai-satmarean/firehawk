#!/usr/bin/expect -f

log_user 0
#stty -echo

# need to remove this list array method. consider injecting pass as encrypted env var now
set hostname [lindex $argv 0];
set port [lindex $argv 1];
set tier [lindex $argv 2];
stty -echo
set password [lindex $argv 3];
stty echo

set force_conservative 0; # set to 1 to force conservative mode even if script wasn't run conservatively originally
if {$force_conservative} {
	set send_slow {1 .1}
	proc send {ignore arg} {
		sleep .1
		exp_send -s -- $arg
	}
}

# pipe encrypted secret in and use keybase pass to retrieve
set timeout -1

spawn ./scripts/firehawk-ssh.sh $hostname $port $tier
match_max 100000
log_user 1
#stty echo
expect {
    "Vault password (/secrets/keys/*):" {
		stty -echo
        send $password\r
        expect eof
		stty echo
    }
    eof {}
}