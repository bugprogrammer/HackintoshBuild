#!/bin/bash

#arr=(`echo $1 | tr ',' ' '`)
#
#for i in ${arr[*]}; do
#    type=$(curl -s -f $i | grep strings | grep 'SU_TITLE' | awk -F= '{print $NF}' | sed "s/\"//g")
#    if [[ $type =~ "Beta" ]]; then
#        version=$(curl -s -f $i | grep string | head -n 2 | sed "s/<string>//g" | sed "s/<\/string>//g" | xargs | awk '{for(i=0;i<=NF-1;i++)printf("%s ",$(NF-i));printf("\n");}' | sed "s/[ \t]*$//g" | sed 's/ / Beta(/g')
#    else
#        version=$(curl -s -f $i | grep string | head -n 2 | sed "s/<string>//g" | sed "s/<\/string>//g" | xargs | awk '{for(i=0;i<=NF-1;i++)printf("%s ",$(NF-i));printf("\n");}' | sed "s/[ \t]*$//g" | sed 's/ /(/g')
#    fi
#
#    if [[ $version =~ "10.13" ]]; then
#            echo "macOS High Sierra "$version")"
#        elif [[ $version =~ "10.14" ]]; then
#            echo "macOS Mojave "$version")"
#        elif [[ $version =~ "10.15" ]]; then
#            echo "macOS Catalina "$version")"
#    fi
#done

arr=(`echo $1 | tr ',' ' '`)

for i in ${arr[*]}; do
    type=$(curl -s -f $i | grep suDisabledGroupID)
    if [[ $type =~ "Beta" ]]; then
        type=" Beta"
    else
        type=""
    fi
    version=$(curl -s -f $i | grep -C 1 "<key>VERSION</key>" | sed "s/<string>//g" | sed "s/<\/string>//g" | sed "s/<key>//g" | sed "s/<\/key>//g" | sed "s/VERSION//g" | xargs | awk '{for(i=0;i<=NF-1;i++)printf("%s ",$(NF-i));printf("\n");}' | sed "s/[ \t]*$//g" | sed "s/ /$type(/g")
        if [[ $version =~ "10.13" ]]; then
                echo "macOS High Sierra "$version")"
            elif [[ $version =~ "10.14" ]]; then
                echo "macOS Mojave "$version")"
            elif [[ $version =~ "10.15" ]]; then
                echo "macOS Catalina "$version")"
            elif [[ $version =~ "10.16" ]]; then
                echo "macOS Big Sur "$version")"
            elif [[ $version =~ "11" ]]; then
                echo "macOS Big Sur "$version")"
        fi
done
