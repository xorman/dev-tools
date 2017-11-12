#!/bin/bash
#                                                                              |
die() { echo "${0##*/}: error: $*" >&2 && exit 1
}

# Defaults
bridge_count=1
phys_if='eth0'
bridge_of_phys_if='br0'

help() {
cat << EOF
Creates a virtual Ethernet switch / bridge through the use of the brctl 
application. Adds interfaces to the created bridge(s) and $phys_if to bridge 
$bridge_of_phys_if by default.

Usage: `basename $0` interface-count [OPTION]...
    interface-count    Number of virtual interfaces per bridge
    -h, --help         Display this help and exit
    -p <interface>     Physical interface that will be connected to $bridge_of_phys_if.
                       Default is $phys_if. No one added with (-p none).
    -b <bridge-count>  Number of virtual bridges that are created. Default 1

Show the result with: brctl show 
EOF
exit 1
}


parse_user_input() {
  (($#)) || help
  [ $# -ge 1 ] && [ "$1" = "-h" -o "$1" = "--help" ] &&  help

  # Permission check
  [ $(whoami) == "root" ] || die 'This script must run as root'  
  
  # Positional arguments
  if ! [[ $1 =~ ^[0-9]+$ ]]; then 
    die "$1 is not a valid interface count"
  fi
  interface_max=$(( $1 - 1 ))
  shift
  
  # Optional arguments
  local flag
  while getopts 'b: p:' flag; do
    case $flag in
      p) phys_if=$OPTARG;;
      b) bridge_count=$OPTARG;;
      *) exit 1 ;;
    esac
  done
  
  bridge_max=$(( $bridge_count - 1 ))
}


create_bridge_and_interfaces() {
  for br_idx in $(seq 0 $bridge_max); do
    brctl addbr br$br_idx
    for i in $(seq 0 $interface_max); do
      ip tuntap add mode tap br${br_idx}p$i
      brctl addif br$br_idx br${br_idx}p$i
      ifconfig br${br_idx}p$i up
    done
  done
  
  if ! [[ "$phys_if" == "none" ]]; then
    brctl addif $bridge_of_phys_if $phys_if
    ifconfig $phys_if 0
    dhclient $bridge_of_phys_if
  fi
}


main() {
  type brctl  > /dev/null 2>&1
  (($?)) && die 'Application brctl is not installed'
  parse_user_input "$@"
  create_bridge_and_interfaces
}


main "$@"
exit 0

