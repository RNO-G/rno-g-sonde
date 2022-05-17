#! /bin/sh 

. ./setup.sh 

echo "Remote is ftp://${SONDE_FTP_HOST}/${SONDE_FTP_DIR}/${SONDE_FTP_PATTERN} newer than ${SONDE_FTP_CUTOFF}"
if [ -w "${SONDE_RAW_DATA_DIR}" ]
then 
  echo "Storing raw data to ${SONDE_RAW_DATA_DIR}" 
else 
  echo "${SONDE_RAW_DATA_DIR} is not writable, aborting" 
  exit 1
fi


if [ -w "${SONDE_ROOT_DATA_DIR}" ]
then 
echo "Storing rootified data to ${SONDE_ROOT_DATA_DIR}"
else 
  echo "${SONDE_ROOT_DATA_DIR} is not writable, aborting" 
  exit 1
fi

echo "Rootifying the following datasets: ${SONDE_DATASETS}"



echo "Starting transfer..."
echo lftp -c "\"set ftp:sync-mode off; open ${SONDE_FTP_HOST} ;  mirror -r -n -I '${SONDE_FTP_PATTERN}' -N  ${SONDE_FTP_CUTOFF} ${SONDE_FTP_DIR}/ ${SONDE_RAW_DATA_DIR}/ ;\""
lftp -c "set ftp:sync-mode off; open ${SONDE_FTP_HOST} ;  mirror -r -n -I '${SONDE_FTP_PATTERN}' -N  ${SONDE_FTP_CUTOFF} ${SONDE_FTP_DIR}/ ${SONDE_RAW_DATA_DIR}/ ;"
echo "Transfer done" 

echo "Checking what needs to be rootified" 

echo " {\"files\" : [ " > ${SONDE_JSON_FILE}

first=1

for fullmwxfile in ${SONDE_RAW_DATA_DIR}/* ; 
do
  mwxfile=${fullmwxfile##*/}
  rootfile=${mwxfile%.mwx}.root

  if [ "$fullmwxfile" -nt ${SONDE_ROOT_DATA_DIR}/$rootfile ] ; 
  then 
    mwx2root $fullmwxfile -o ${SONDE_ROOT_DATA_DIR}/$rootfile ${SONDE_DATASETS}
  fi 
  if [ $first -eq 0 ] 
  then 
    echo -n "  ," >> ${SONDE_JSON_FILE} 
  else 
    echo -n "   " >> ${SONDE_JSON_FILE} 
  fi

  first=0
  echo \"$rootfile\" >> ${SONDE_JSON_FILE}
done 

echo  ] } >> ${SONDE_JSON_FILE}



