#!/bin/bash

set -eo pipefail

#####################################################################################################################################
# script is responsible for setting up postfix environment and installing dums script.                                              #
# script need to be provided with three arguement which are sender_emailid ,sender_passwd and listofip                              #
# Example:                                                                                                                          #
# ./multi-mail-setup.sh sender_emailid sender_passwd listofip                                                                       #
#                                                                                                                                   #
# It download dums.sh script and take care that dums.sh is executed every hour on all the machine listed in listofip file.          #
# It also creates an dums.conf file and inserts mailids and threshold_disk_space if explicitly mentioned in this script to it.      #
# mailid are extracted from mailids variable in this script. Format for the same is like:                                           #
#                                                                                                                                   #
# mailids=(reciever1@company.com reciever2@company.com)                                                                             #
# there can be any number of space separated mailid in mailids varaible and all of them would be notified at appropriate condition  #
#####################################################################################################################################

ssh_username="root"
ips=()
mail_setup_url="https://raw.githubusercontent.com/kr-jaydeepp/shellscript-test/master/mail-setup.sh"

main() {
    # checks if two arguements are suppied or not
    if [[ $# -ne 3 ]] ; then
        echo "Error: pass emailid, passwd and file with list of IP as arguements to the script!
        Example: ./multi_mail_setup.sh sender_emailid sender_passwd listofip"
        exit 1
    fi 

    # get the list of IP addresses
    if [[ -f "$3" ]]; then
        # read from the $1
        while read -r line; do
            ips+=("$line")
        done < "$3"
    else
        echo "Error: pass a file with list of IP as third arguement to script"
        exit 1
    fi

    for ip in "${ips[@]}"; do
        # run the setup script on the VPS
        echo "Running the setup script on the remote VPS at $ip"
        ssh -o StrictHostKeyChecking=no "${ssh_username}@${ip}" '
        wget $mail_setup_url
        bash ./mail-setup.sh $1 $2
        '

        echo "Mail-setup completed for $ip"
    done
}

main "$@"