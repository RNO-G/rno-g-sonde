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

if [ -w "${SONDE_JSON_DATA_DIR}" ]
then 
echo "Storing json files to ${SONDE_JSON_DATA_DIR}"
else 
  echo "${SONDE_JSON_DATA_DIR} is not writable, no json" 
  exit 1
fi



echo "Rootifying the following datasets: ${SONDE_DATASETS}"



echo "Starting transfer..."
echo lftp -c "\"set ftp:sync-mode off; open ${SONDE_FTP_HOST} ;  mirror -r -n -I '${SONDE_FTP_PATTERN}' -N  ${SONDE_FTP_CUTOFF} ${SONDE_FTP_DIR}/ ${SONDE_RAW_DATA_DIR}/ ;\""
lftp -c "set ftp:sync-mode off; open ${SONDE_FTP_HOST} ;  mirror -r -n -I '${SONDE_FTP_PATTERN}' -N  ${SONDE_FTP_CUTOFF} ${SONDE_FTP_DIR}/ ${SONDE_RAW_DATA_DIR}/ ;"
echo "Transfer done" 

echo "Checking what needs to be rootified" 


if [ -w "${SONDE_JSON_DATA_DIR}" ]
then 
echo " {\"sondes\" : [ " > ${SONDE_JSON_FILE}.tmp
fi

first=1

for fullmwxfile in ${SONDE_RAW_DATA_DIR}/* ; 
do
  mwxfile=${fullmwxfile##*/}
  name=${mwxfile%.mwx}
  rootfile=${name}.root
  gpxfile=${name}.gpx
  jsonfile=${SONDE_JSON_DATA_DIR}/${name}.json

  if [ "$fullmwxfile" -nt ${SONDE_ROOT_DATA_DIR}/$rootfile ] ; 
  then 
    mwx2root $fullmwxfile -o ${SONDE_ROOT_DATA_DIR}/$rootfile ${SONDE_DATASETS}
  fi 

  if [ "$fullmwxfile" -nt ${SONDE_GPX_DATA_DIR}/$gpxfile.gz ] ; 
  then 
    echo "root -b -q makegpx.C\(\"${SONDE_ROOT_DATA_DIR}/$rootfile\",\"${SONDE_GPX_DATA_DIR}/$gpxfile\",\"$name\",\"$jsonfile\"\)"
    root -b -q makegpx.C\(\"${SONDE_ROOT_DATA_DIR}/$rootfile\",\"${SONDE_GPX_DATA_DIR}/$gpxfile\",\"$name\",\"$jsonfile\"\)
    rm -f ${SONDE_GPX_DATA_DIR}/$gpxfile.gz  #in case there's an older version for some reason
    gzip ${SONDE_GPX_DATA_DIR}/$gpxfile 
  fi


  if [ -w "${SONDE_JSON_DATA_DIR}" ]
  then 
    if [ $first -eq 0 ] 
    then 
      echo -n "  ," >> ${SONDE_JSON_FILE}.tmp
    else 
      echo -n "   " >> ${SONDE_JSON_FILE}.tmp
    fi
    first=0
    cat $jsonfile >> ${SONDE_JSON_FILE}.tmp
  fi 

done 

if [ -w "${SONDE_JSON_DATA_DIR}" ]
then 
  echo  ] } >> ${SONDE_JSON_FILE}.tmp
  mv ${SONDE_JSON_FILE}.tmp ${SONDE_JSON_FILE} 
fi 

