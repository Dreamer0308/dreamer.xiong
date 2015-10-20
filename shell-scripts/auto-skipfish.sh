#!/bin/bash

# This script is to use skipfish to scan all our customer websites,
#   it will generate a log to record all scan status and send a report email daily,
#     as per Fraser's requirement, we also send this report to our sugar server daily.
#       As skipfish will cost server's resource, we only run skipfish for 3 websites in every early morning.

SKIPFISH=$(which skipfish)
SKIPFISH_HOME="/var/www/sites/skipfish"
URL_LISTS="/opt/ncscripts/skipfish/skipfish_urls.txt"
MKDIR=$(which mkdir)
DATE=$(date +%Y%m%d%H%M%S)
DICT="/usr/share/skipfish/dictionaries/minimal.wl"
WR_DICT="/root/writedictionary.txt"
REPORT_WEB="http://123.103.98.72:81"
REPORT_LOG="/opt/ncscripts/skipfish/$DATE-report.log"
LOCK_FILE="/opt/ncscripts/skipfish/lock-$DATE"
ERROR_LOG="/opt/ncscripts/skipfish/$DATE-error.log"
SENDMAIL=$(which sendmail)
URL_START_POINT=$(($(($(date +%d)-1))*3+1))
URL_NUM=$(cat $URL_LISTS |awk '{print $1}'|sed -n $URL_START_POINT,$(($URL_START_POINT+2))p|wc -l)

#Check args
if [ $# -ne 1 ]; then
  echo "Wrong arguments!"  | tee -a $ERROR_LOG
  echo "[Usage] - bash /opt/ncscripts/skipfish/skipfish_report.sh \$skipfish_urls.txt"
  exit
else
  URL_LISTS=$1
fi

#Check if there are any URL needs to be scaned
if [ $URL_NUM -eq 0 ]; then
  echo "No URLs need to be scaned today" >> $REPORT_LOG
  exit 1
else
  echo "Found urls, will run skipfish for following urls:" > $REPORT_LOG
  cat $URL_LISTS |awk '{print $1}'|sed -n $URL_START_POINT,$(($URL_START_POINT+2))p >> $REPORT_LOG
fi

skipfish_report () {
echo >> $REPORT_LOG
echo >> $REPORT_LOG
echo "Running skipfish:"   >> $REPORT_LOG
echo "-----------------------------------------------------------------------------------------------------------------------"   >> $REPORT_LOG
echo "website                                    report_status          report_link" >> $REPORT_LOG

CHECK_STATUS=0

for i in $(cat $URL_LISTS |awk '{print $1}'|sed -n $URL_START_POINT,$(($URL_START_POINT+2))p)
do
  if [ -n $i ]; then
    COMPANY_NAME=$(grep $i $URL_LISTS|awk '{print $2}')
    WEBSITE_NAME=$(echo $i|awk -F '/' '{if($i ~ /http/) {print $3} else {print $1}}')

    #create random url for the secure website report
    TIME=$(date +%s.%N)
    RANDOM_CHAR=$(cat /dev/urandom | tr -dc "a-zA-Z0-9_+\~\!\@\#\$\%\^\&\*\(\)"| fold -w 32 |head -n 1)
    REPORT_LINK=$(echo $RANDOM_CHAR$TIME| sha256sum |awk '{print $1}')
    REPORT_FOLDER=$SKIPFISH_HOME/$COMPANY_NAME/$WEBSITE_NAME-$REPORT_LINK
    $MKDIR -p $REPORT_FOLDER

    #As per Steve, we can limite the total request to 10000 and the rate of requests to 1r/s to reduce the website stress
    #/usr/bin/skipfish -o /skipfishOMPScan/ -S /usr/share/skipfish/dictionaries/minimal.wl -W writedictionary.txt http://www.thepaper.cn/ 
    $SKIPFISH -o $REPORT_FOLDER -S $DICT -W $WR_DICT -l 1 -g 1 -m 1 -r 10000 -f 1000 $i 2>>$ERROR_LOG > /dev/null

    #Check if there is any scan failed
    if [ $? -eq 0 ]; then
      echo "$WEBSITE_NAME           OK                                  $REPORT_WEB/$COMPANY_NAME/$WEBSITE_NAME-$REPORT_LINK" >> $REPORT_LOG
    else
      echo "$WEBSITE_NAME           FAILED                              Scan failed, please check the error log: $ERROR_LOG" >> $REPORT_LOG
      CHECK_STATUS=1
    fi

    sleep 10

  else
    break

  fi

done

echo "------------------------------------------------------------------------------------------------------------------------" >> $REPORT_LOG
echo "Skipfish completed."    >> $REPORT_LOG
}

#Sent repot email to PM_NOTIFY
report_mail () {

mail_addr1="dreamer.xiong@chinanetcloud.com"
#mail_addr2="pm_auto_notify@chinanetcloud.com"
#mail_addr3="fraser.smith@chinanetcloud.com"
mail_addr2=
mail_addr3=
STATUS=

if [ -s $ERROR_LOG -o $CHECK_STATUS -ne 0 ];
then
  STATUS="FAILED"
else
  STATUS="OK"
fi

cat $REPORT_LOG | mail -s "Skipfish Report - $(date +%Y-%m-%d) [$STATUS]" $mail_addr1 $mail_addr2 $mail_addr3
}


main () {

touch $LOCK_FILE

skipfish_report

rm -f $LOCK_FILE

}


#Check if the process is running or stuck 
if [ -e $LOCK_FILE ]; then
  echo "skipfish is running, probable stuck, please check it!" >> $REPORT_LOG
  exit 1
else
  main
fi

#Per Fraser, we can send the report to our sugar server then he send the report to customer automatically through sugar
scp -P40025 -i /opt/ncscripts/skipfish/.key/id_rsa $REPORT_LOG skipfish@61.129.13.23:/tmp/

if [ $? -ne 0 ]; then
  echo "Failed to send the report to sugar server" >> $REPORT_LOG
else
  echo "Report has been sent to sugar server successfully." >> $REPORT_LOG
fi


report_mail

