#!/usr/bin/env bash
## Fork: arch-install-script by  Camille TJHOA https://github.com/ctjhoa/arch-install-script.git
## Author: Narges Ahmadi (NarcisLinux)  Email:n.sedigheh.ahmadi@gmail.com
## Arch-install-script is for install and config arch linux.
##
## install-arch.sh
##  partitioning
##
##
#############Authentication#############

    if [ $(id -u) -ne 0 ]
    then
        echo "ArchInstallScript:   Error: Permission denied, Change me or run me as root!"
        exit
    fi

#############Functions#############


            parsconffiletojson() {
            # Function parsconffiletojson sould convert ini file config to json format.
        LineNumber=1
        #EndLine=            //assigned value in code
        FilenameIni="$1"
        FilenameIniWithOutCom=$(mktemp /tmp/ArchInstallScript.XXXXXX)


        cat $FilenameIni |grep -v "^#" |grep -v "^;"|grep -v "^$"  > $FilenameIniWithOutCom
        EndLine=$(wc -l < $FilenameIniWithOutCom)

        echo "{"
        while read i
        do
          if [[ "$i" == [* ]]
          then
            echo "$i" | sed 's/\[\(.*\)\]/\  "\1":{/'

            if [[ $( sed -n $(($LineNumber+1))p $FilenameIniWithOutCom ) == [* ]]
            then
               echo "  },"
            elif [[ $LineNumber == $EndLine ]]
            then
               echo "  }"
            fi
            LineNumber=$((LineNumber+1))
          else

            if [[ ! $(echo $i |grep "=")  ]]
            then
                echo -e "ArchInstallScript: Config file $1 \e[31mError\e[0m Line $LineNumber, what's the meaning of '$i'!"
                exit
            elif [[ -z $(echo $i | sed 's/\(.*\)=\(.*\)/\2/') ]]
            then
                echo -e "ArchInstallScript: Config file $1 \e[31mError\e[0m Line $LineNumber, '$i' has no value!"
                exit
            fi

            if [[ $( sed -n $(($LineNumber+1))p $FilenameIniWithOutCom ) == [* ]] ||  [[ $LineNumber == $EndLine ]]
            then
                echo "$i" |sed 's/"/\\"/g' |sed 's/\(.*\)=\(.*\)/        "\1": "\2"/' && LineNumber=$((LineNumber+1))

                if [[ $(($LineNumber-1)) == $EndLine ]]
                then
                    echo "  }"
                else
                    echo "  },"
                fi

            else
                echo $i |sed 's/"/\\"/g' | sed 's/\(.*\)=\(.*\)/        "\1": "\2",/' && LineNumber=$((LineNumber+1))
            fi

          fi
        done < $FilenameIniWithOutCom

        echo "}"

     }



            partitioning() {


        if [  -z $2 ] || [ -z $1 ] ; then
            # List the partitions of all or the specified devices.
            sudo sfdisk -l $1
            exit
        else

            case "$1" in

            # Delete all or the specified partitions.
            --delete)   echo "ArchInstallScript:   Delete all or the specified partitions $2."
                        sfdisk --delete $2
                ;;
             # Create partitions.
            --create)   echo "ArchInstallScript:   Sizes of $2 in units of 1024 byte size:"
                        sfdisk $2
                ;;
            # Dump the partitions of a device in a format that is usable as input to sfdisk.
            -d)         echo "ArchInstallScript:   Dump the partitions $2 of a device in a format that is usable as input to sfdisk."
                        sfdisk -d $2
                ;;
            # List the sizes of all or the specified devices in units of 1024 byte size.
            -s)         echo "ArchInstallScript:   Sizes of $2 in units of 1024 byte size:"
                        sfdisk -s $2
                ;;
            esac

        fi

            }


            partitionformat() {
        #PartitionNumber=            //assigned value in code
        #PartitionType=              //assigned value in code
        FilenamePartitionList=$(mktemp /tmp/ArchInstallScript.XXXXXX)
        sfdisk -d $1 |grep "^$1" > $FilenamePartitionList

        while read i
        do
            PartitionNumber=$(echo $i|cut -d ":" -f 1)
            PartitionType=$(echo $i|cut -d "," -f3|cut -d "=" -f2)

            case $PartitionType in
            EBD0A0A2-B9E5-4433-87C0-68B6B72699C7)   mkfs.fat -F32  $PartitionNumber
            ;;
            0FC63DAF-8483-4772-8E79-3D69D8477DE4)   mkfs.ext4 $PartitionNumber
            ;;
            C91818F9-8025-47AF-89D2-F030D7000C2C)   mkswap $PartitionNumber && swapon $PartitionNumber
            ;;
            esac

        done <$FilenamePartitionList

            }

                checkinternetconnection() {

            if [[ ! $(ping -c $1) ]]
            then
                echo -e "\e[34mArchInstallScript:\e[0m  Error, internet connection disconnected!"
                read -p "Is it OK? [y=yes] "  FlagConfig

                if [[ $FlagConfig = y ]] || [[ $FlagConfig = Y ]]
                then
                    echo -e "\e[34mArchInstallScript:\e[0m Well then let's go! "
                else
                    echo -e "\e[34mArchInstallScript:\e[0m Error, check your Network config file!"
                    exit
                fi
            fi
            else
                echo -e "\e[34mArchInstallScript:\e[0m Network connection is Ok ! "
            fi
            }

#############Variables#############
#FlagConfig=            //assigned value in code
#PartitionName=         //assigned value in code
#PartitionFullName=     //assigned value in code
#PartitionNameRoot=     //assigned value in code
PartitionDevice="/dev/sdd"
FilenameConfigIni="./install.conf.sample"
FilenameConfigJson=$(mktemp /tmp/ArchInstallScript.XXXXXX)
FilenamePartitionName=$(mktemp /tmp/ArchInstallScript.XXXXXX)
#############Trap#############
#trap "rm -rf /tmp/ArchInstallScript*;exit" 0 2 15
#trap "echo -e \e[34mArchInstallScript:\e[0m Finished successfully" 0
#--------------Primary code--------------#
#

parsconffiletojson "$FilenameConfigIni" > $FilenameConfigJson

#partitioning --delete $PartitionDevice
#cat $FilenameConfigJson |jq -r .Partition[] |partitioning --create $PartitionDevice
#partitionformat $PartitionDevice


grep "^sdx" $FilenameConfigIni> $FilenamePartitionName
echo -e "\e[34mArchInstallScript:\e[0m Yor config :
$(cat $FilenamePartitionName)"

read -p "Is it OK? [y=yes] "  FlagConfig

if [[ $FlagConfig = y ]] || [[ $FlagConfig = Y ]]
then
    echo -e "\e[34mArchInstallScript:\e[0m Well then let's go! "
else
    echo -e "\e[34mArchInstallScript:\e[0m Error, check your config file!"
    exit
fi

PartitionNameRoot=$(grep "_root" $FilenamePartitionName |sed 's/^sdx\(.*\)_root\(.*\)/\1/' )
grep "^sdx" $FilenameConfigIni |grep -v "_root" > $FilenamePartitionName

mount $PartitionDevice$PartitionNameRoot /mnt


while read PartitionName
do

    if [[ $(echo $PartitionName|grep  "_efi") ]]
    then
        PartitionName=$(echo $PartitionName |sed 's/^sdx\(.*\)_efi\(.*\)/\1/' )
        if [ ! -e /mnt/boot/efi ];then mkdir -p /mnt/boot/efi;fi
        mount $PartitionDevice$PartitionName /mnt/boot/efi
    elif [[ $(echo $PartitionName|grep  "_home") ]]
    then
        PartitionName=$(echo $PartitionName|sed 's/^sdx\(.*\)_home\(.*\)/\1/' )
        if [ ! -e /mnt/home ];then mkdir -p /mnt/home;fi
        mount $PartitionDevice$PartitionName /mnt/home
    elif [[ $(echo $PartitionName|grep  "_swap") ]]
    then
        true
    else
        PartitionFullName=$(echo $PartitionName|sed 's/^sdx\(.*\)_\(.*\)=\(.*\)/\2/' )
        PartitionName=$(echo $PartitionName|sed 's/^sdx\(.*\)_\(.*\)/\1/' )
        if [ ! -e /mnt/media/$PartitionFullName ];then mkdir -p /mnt/media/$PartitionFullName;fi
        mount $PartitionDevice$PartitionName /mnt/media/$PartitionFullName
    fi

done < $FilenamePartitionName

checkinternetconnection 8.8.8.8
#pacstrap /mnt base base-devel
genfstab -U /mnt >> /mnt/etc/fstab
 /mnt

arch-chroot /mnt

#chroot /home/mayank/chroot/codebase /bin/bash <<"EOT"
#cd /tmp/so
#ls -l
#echo $$
#EOT
exit 0

#
#--------------End--------------#
