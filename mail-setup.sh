#!/bin/bash

#####################################################################################################################################
# script is responsible for setting up postfix environment                                                                          #
#                                                                                                                                   #
# It also creates an dums.conf file and inserts mailids and threshold_disk_space if explicitly mentioned in this script to it.      #
# mailid are extracted from mailids variable in this script. Format for the same is like:                                           #
#                                                                                                                                   #
# mailids=(reciever1@company.com reciever2@company.com)                                                                             #
# there can be any number of space separated mailid in mailids varaible and all of them would be notified at appropriate condition  #
#####################################################################################################################################

sender_mailid="$1"

sender_mailid_passwd="$2"

#array of reciever email ids
mailids=(jaydeep.purohit@knackroot.com jaydeeppurohit1996@gmail.com)

threshold_disk_space=10

#postfix config file
postfix_conf_file='/etc/postfix/main.cf'

#posfix password file
postfix_passwd_file='/etc/postfix/sasl_passwd'

# dums script url
dums_script_url='https://raw.githubusercontent.com/dexergiproject/dxr-mn-scripts/master/dums.sh'

# scripts directory
dums_script_dir="$HOME/dums"

#file which stores configuration
dums_config_file="$dums_script_dir/dums.conf"

download_dums()
{
        # checks for absence of dir 
        if [[ ! -d "$dums_script_dir" ]] ; then
                #create an directory for dums in home.
                mkdir "$dums_script_dir"
        fi

        # download dums script on machine
        wget -O "$dums_script_dir/dums.sh" "$dums_script_url"
}

create_dums_config()
{
        # checks if file is regular file and non-zero size
        if [[ -f "$dums_config_file" && -s "$dums_config_file"  ]] ; then
                echo "$dums_config_file already exists."
        else
                # enters email id's inside the config file
                for mailid in "${mailids[@]}" ; do
                        echo "mailid=$mailid" >> "$dums_config_file"
                done
        fi

        # checks if threshold_disk_space variable present in this script and is non empty then it add it to dums.conf file
        if [[ -n "$threshold_disk_space" ]] ; then
                echo "threshold_disk_space=$threshold_disk_space" >> "$dums_config_file"
        fi        
}

# checks if two arguements are suppied or not
if [[ $# -ne 2 ]] ; then
        echo "Error: pass emailid and passwd as arguements to the script!
Example: ./mail_setup.sh sender_emailid sender_passwd"
        exit 1
fi

# installs the required packages 
sudo DEBIAN_FRONTEND=noninteractives apt-get -y install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules

# checks if any error occured during package installation
if [[ $? -ne 0 ]]; then
        echo "Error occured while downloading packages"
        exit 1
fi

# appends postfix config files
cat <<EOF | sudo tee -a "$postfix_conf_file"
relayhost = [smtp.gmail.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_use_tls = yes
EOF

# adds email password to /etc/postfix/sasl_passwd file
echo "[smtp.gmail.com]:587    $sender_mailid:$sender_mailid_passwd" > "$postfix_passwd_file"

# Fix permission and update postfix config to use sasl_passwd file
sudo chmod 400 "$postfix_passwd_file"
sudo postmap "$postfix_passwd_file"

# reloads postfix config for changes to take effect
sudo /etc/init.d/postfix reload

echo "Setup for postfix completed"
#echo "Setup for postfix is successfully " | mail -s "[$HOSTNAME] Test Postfix" jaydeep.purohit@knackroot.com

download_dums

create_dums_config

# creates file inside dums_script_dir as executable
sudo chmod +x "$dums_script_dir/dums.sh"

# adds the script in crontab so that it runs the script every hour.
(crontab -l 2>/dev/null; echo "@hourly cd $dums_script_dir && ./dums.sh") | crontab -
