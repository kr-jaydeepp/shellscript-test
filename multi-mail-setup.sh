#!/bin/bash

#####################################################################################################################################
# script is responsible for setting up postfix environment and installing dums script on multiple VPS.                              #
# script need to be provided with three arguement which are sender_emailid ,sender_passwd and file_listofip                         #
# Example:                                                                                                                          #
# ./multi-mail-setup.sh sender_emailid sender_passwd listofip                                                                       #
#                                                                                                                                   #
# It download dums.sh script and take care that dums.sh is executed every hour on all the machine listed in listofip file.          #
#####################################################################################################################################

#ssh username
ssh_username="root"

#location of mail-setup script
mail_setup_url="https://raw.githubusercontent.com/kr-jaydeepp/shellscript-test/master/mail-setup.sh"

#Path address for mail-setup script 
mail_setup_script="$HOME/mail-setup.sh"

#array of IP's
ips=()

main() {
    # checks if three arguements are suppied or not
    if [[ $# -ne 3 ]] ; then
        echo "Error: pass emailid, passwd and file with list of IP as arguements to the script!
Example: ./multi_mail_setup.sh sender_emailid sender_passwd listofip"
        exit 1
    fi 

    # get the list of IP addresses, true if file exits and it's a regular file
    if [[ -f "$3" ]]; then
        # read from the $1
        while read -r line; do
            #check if variable is non-empty string
            if [[ -n "$line" ]] ; then
                ips+=("$line")
            fi
        done < "$3"
    else
        echo "Error: pass a file with list of IP as third arguement to script"
        exit 1
    fi

    for ip in "${ips[@]}"; do
        # run the setup script on the VPS
        echo "Running the setup script on the remote VPS at $ip"
        ssh -o StrictHostKeyChecking=no "${ssh_username}@${ip}" '
        wget -O "$mail_setup_script" '"${mail_setup_url}"';
        bash '"${mail_setup_script}"' '"${1}"' '"${2}"';
        rm '"${mail_setup_script}"'
        '

        echo "Mail-setup completed for $ip"
    done
}

main "$@"