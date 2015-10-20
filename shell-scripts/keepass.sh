#!/bin/bash

#This script is used to download the newest keepass file from our webdev, and open the keepass file automaticlly
#No need use root user to run this script
#Last modified 2015-02-01 4:23 am

KEEPASS_URL="https://webdav.service.chinanetcloud.com/Departments/Operations/Op-Internal/Access/Keepass"
INDEX_HTML_FILE="/home/dreamer/keepass/index.html"
KEEPASS_HOME="/home/dreamer/keepass"
LOG_FILE="/home/dreamer/keepass/download.log"
USERNAME=
PASSWD=
KEEPASS_PASSWD=

script_help() {

  printf "Usage: %s: [-h] [-u] [-p]  [-k] args" 

  echo
  echo "-h | --help                            -- display help (this)"
  echo "-u | --username                        -- your webdev account"
  echo "-p | --password                        -- your webdev password"
  echo "-k | --kpassword                       -- the password to open keepass file"
  echo
  echo "Usage: bash keepass.sh -u WEBDEV_ACCOUNT -p WEBDEV_PASSWD -k KEEPASS_PW"
  echo
  echo "Friendly reminder: you can add a alias in .bashrc file, such as: alias keepass='bash keepass.sh -u dreamer.xiong -p ***** -k *****'"
}

if [ $# -eq 0 ]; then
  script_help
  exit 
fi

get_option(){

#Usage of getopt
#getopts，它不支持长选项
#如果需要支持长选项以及可选参数，那么就需要使用getopt
#-o表示短选项，两个冒号表示该选项有一个可选参数，可选参数必须紧贴选项
#如-carg 而不能是-c arg
#--long表示长选项
#"$@"所有参数
# -n:出错时的信息
# -- ：举一个例子比较好理解：
#我们要创建一个名字为 "-f"的目录你会怎么办？
# mkdir -f #不成功，因为-f会被mkdir当作选项来解析，这时就可以使用
# mkdir -- -f 这样-f就不会被作为选项

OPTIONS=`getopt --options hu:p:k: \
         --long help,username:,password:,kpassword: \
         -- "$@"`

## exit if the options have not properly been gathered
if [ $? != 0 ] ; then echo "Terminating...probably wrong parameter, use -h to check the usage of this script" >&2 ; exit 1 ; fi

# Note the quotes around `$OPTIONS': they are essential!
## 会将符合getopt参数规则的参数摆在前面，其他摆在后面，并在最后面添加--
eval set -- "$OPTIONS"

while true ; do
    case "$1" in
      -h|--help) script_help ; exit ;;
      -u|--username) USERNAME=$2 ; shift 2 ;;
      -p|--password) PASSWD=$2  ; shift 2 ;;
      -k|--kpassword) KEEPASS_PASSWD=$2  ; shift 2 ;;
      --) shift; break ;;
      *) script_help ; exit 1 ;;
    esac
done
}

get_option "$@"
  
#check keepass home directory
if [ ! -d $KEEPASS_HOME ]; then 
  mkdir -p $KEEPASS_HOME
fi

##check permission of keepass home directory
#if [ ! -r $KEEPASS_HOME -o ! -w $KEEPASS_HOME ]
#  echo "can not write/read to the folder $KEEPASS_HOME, please check folder permission" |tee -a $LOG_FILE
#fi

#clean old keepass data

echo >>  $LOG_FILE
echo >>  $LOG_FILE
echo "Keepass starts - `date` " >> $LOG_FILE
echo >>  $LOG_FILE

if [ "`ls -A $KEEPASS_HOME`" = "" ]; then
  echo "$KEEPASS_HOME is indeed empty"  
else
  echo "$KEEPASS_HOME is not empty, will remove old data"
  rm -f $KEEPASS_HOME/$INDEX_HTML_FILE $KEEPASS_HOME/$LOG_FILE
fi

#Check keepassx binary
KEEPASSX=$(which keepassx)
if [ $? -ne 0 ]; then
  echo "Didn't find keepassx command, make sure you are using KeepassX, otherwise, you need make some changes in the script!" |tee -a $LOG_FILE
  exit
fi

#Download main page
echo
echo "Checking new keepass files, please wait for a moment"
wget $KEEPASS_URL --user=$USERNAME --password=$PASSWD -O $INDEX_HTML_FILE &>> $LOG_FILE 

if [ $? -eq 0 ]; then
  echo                               >> $LOG_FILE
  echo "HTML download successfully!" >> $LOG_FILE
else
  echo "didn't download the html file, please check the script!" |tee -a $LOG_FILE
  exit
fi

if [ `cat $INDEX_HTML_FILE |grep kdb|wc -l` -eq 0 ]; then
  echo "No keepass file found, will open old keepass file" |tee -a $LOG_FILE
  KEEPASS_FILE=$(ls -t $KEEPASS_HOME |grep kdb|grep -v lock|sort -nr |head -1)
else
  echo                                   |tee -a $LOG_FILE
  echo "Here are the new keepass files on our webdev server:" |tee -a $LOG_FILE
  echo "---------------------------"     |tee -a $LOG_FILE
  echo "$(cat $INDEX_HTML_FILE |egrep -o CNC_PASSWD.+\.kdb|cut -d'"' -f1)" |tee -a $LOG_FILE
  echo "---------------------------"     |tee -a $LOG_FILE
  echo                                   |tee -a $LOG_FILE
  NEW_KEEPASS_FILE=$(cat $INDEX_HTML_FILE |egrep -o CNC_PASSWD.+\.kdb| cut -d '"' -f 1|sort -nr |head -1)
  #Thousands of ways to filter the keepass file name, don't know why I use grep + cut since grep is enough, maybe I was not master enough before 
  #  说到这里，可以学习一下正则表达式的贪婪性，非常有用
  OLD_KEEPASS_FILE=$(ls -t $KEEPASS_HOME |grep kdb|grep -v lock|sort -nr |head -1)
  if [ "$OLD_KEEPASS_FILE" == "$NEW_KEEPASS_FILE" ]; then
    echo "Keepass is not updated, you already download the latest keepass file" |tee -a $LOG_FILE
    #echo "Checking whether you are using the latest keepass file"  |tee -a $LOG_FILE
    KEEPASS_FILE="$OLD_KEEPASS_FILE"
    #check if you already opened latest keepass file
    if [ `ps aux|grep keepassx |grep -v grep|wc -l` -ne 0 ]; then
      #if you use command to open keepass, than ps will show you the keepass file you are using,
      #but if you click the keepass software to open it, than you have to use lsof to check the keepass file you are using
      #lsof cost longer time than ps, but the result will be more correct than ps
      #CURRENT_KEEPASS_FILE=$(lsof |grep keepassx|grep kdb|awk '{print $NF}'|awk -F / '{print $5}')  
      CURRENT_KEEPASS_FILE=$(ps auxf |grep keepassx|grep kdb|awk '{print $NF}'|awk -F / '{print $5}')
      if [ "$CURRENT_KEEPASS_FILE" == "$KEEPASS_FILE" ]; then
        echo
        echo "You already opened the latest keepass file - \"$CURRENT_KEEPASS_FILE\"" | tee -a $LOG_FILE 
    	echo
	    echo "exit!" | tee -a $LOG_FILE
        exit
      else
        echo
        echo "You are using the old keepass file, will reopen the lastest keepass file, enter 'yes' to kill keepass process:"
        read enter
        if [ "$enter" == "yes" -o "$enter" == "y" ]; then
          ps aux|grep keepassx|awk '{print $2}'|xargs kill &> /dev/null
        else
          exit
        fi
      fi
    fi

  else
    echo "Keepass is updated, remove old keepass file and download the latest keepass file" |tee -a $LOG_FILE
    rm -f $KEEPASS_HOME/*.kdb*

    KEEPASS_FILE="$NEW_KEEPASS_FILE"
    wget $KEEPASS_URL/$KEEPASS_FILE --user=$USERNAME --password=$PASSWD -O $KEEPASS_HOME/$KEEPASS_FILE &>> $LOG_FILE
  
    if [ $? -eq 0 ]; then
      echo                                              |tee -a $LOG_FILE
      echo "Download keepass file: $KEEPASS_FILE successfully"         |tee -a $LOG_FILE
      echo "Finish!" |tee -a $LOG_FILE
      echo >> $LOG_FILE
    else
      echo "Didn't download keepass file, check script" |tee -a $LOG_FILE
      exit
    fi
  fi

fi

nohup $KEEPASSX $KEEPASS_HOME/$KEEPASS_FILE &> /dev/null & 
 
echo
echo "Loading............................................."  
echo "Opening the keepass file: $KEEPASS_FILE"
echo ""
echo "Keepass password:"
echo ""
echo "$KEEPASS_PASSWD" 
echo ""




