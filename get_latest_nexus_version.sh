#! /bin/sh +x
BRANCH="$1"
BUILD_TYPE="$2"
URL="${NEXUS_URL}"
ENGINES="$3"
BW_REPO="${LT_REPO}"
BW_GROUPID="${TIL_GROUPID}"
EMS_REPO="${LT_REPO}"
EMS_GROUPID="${EMS_GROUPID}"
EMS_ARTIFACTID="${EMS_ARTIFACTID}"
majv=`echo "${BRANCH}" | awk -F 'CCS' '{print $2}' | cut -d '.' -f 1 | tr -d ' '`
minv=`echo "${BRANCH}" | awk -F 'CCS' '{print $2}' | cut -d '.' -f 2 | tr -d ' '`

case ${BUILD_TYPE} in
        'BW')
                latestBWVersions=""
                [[ -z ${ENGINES} ]] && { echo "ERROR: Please provide engine names"; exit; }
                for engine in $(echo ${ENGINES} | tr ";" "\n")
                do
					    #echo "Engine name is: $engine"
                        cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${BW_REPO}&name=${BW_GROUPID}/${engine}/${majv}_*/${engine}-${majv}_${minv}_*.ear\""
                        eval ${cmd} >nex_output
						# [CICD-349: Fix] - Fixed pagination error
						continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
						while [[ "${continuationToken}" != "null" ]]
						do
							cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${BW_REPO}&name=${BW_GROUPID}/${engine}/${majv}_*/${engine}-${majv}_${minv}_*.ear&continuationToken=${continuationToken}\""
							eval ${cmd} >>nex_output
							continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
						done
						
                        ver=`cat nex_output | grep -e "name" | grep "${engine}.*.ear\"" | sort -V | tail -1 | cut -d '/' -f 3 | tr -d ' '`
                        [[ $ver ]] && latestBWVersions="${latestBWVersions}${engine}:${ver};" || echo "INFO: NO BUILD present for $engine in NEXUS"
                done
                echo "${latestBWVersions}"
                ;;

        'EMS_BUILD')

                [[ -z ${ENGINES} ]] && { echo "ERROR: Please provide engine name"; exit; }
                for engine in $(echo ${ENGINES} | tr ";" "\n")
                do


                        cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${EMS_REPO}&name=${EMS_GROUPID}/${engine}/${majv}_*/${engine}-${majv}_${minv}_*.tar.gz\""
                        eval ${cmd} >nex_output
						# [CICD-349: Fix] - Fixed pagination error
						continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
						while [[ "${continuationToken}" != "null" ]]
						do
							cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${EMS_REPO}&name=${EMS_GROUPID}/${engine}/${majv}_*/${engine}-${majv}_${minv}_*.tar.gz&continuationToken=${continuationToken}\""
							eval ${cmd} >>nex_output
							continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
						done						
                        ver=`cat nex_output | grep -e "name" | grep "${engine}.*.tar.gz\"" | sort -V | tail -1 | cut -d '/' -f 3 | tr -d ' '`
                        if [ ! -z $ver ];then
                           patch_number=`echo ${ver} | cut -d '_' -f 3 | tr -d ' '`
                           trial_number=`echo ${ver} | cut -d '_' -f 1-2 | tr -d ' '`
                           if [ "${trial_number}" == "${majv}_${minv}" ];then
                                   nextEMSVersion="${trial_number}_$((patch_number + 1))"
                           else
                                   nextEMSVersion="${majv}_${minv}_1"
                           fi
                        else
                           nextEMSVersion="${majv}_${minv}_1"
                        fi
                        
                done
                echo "${nextEMSVersion}"
                ;;

        'EMS')
                latestEMSVersion=""
                cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${EMS_REPO}&name=${EMS_GROUPID}/${EMS_ARTIFACTID}/${majv}_*/${EMS_ARTIFACTID}-${majv}_${minv}*.tar.gz\""
                eval ${cmd} >nex_output
				# [CICD-349: Fix] - Fixed pagination error
				continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
				while [[ "${continuationToken}" != "null" ]]
				do
					cmd="curl -X GET \"http://${URL}/service/rest/v1/search?repository=${EMS_REPO}&name=${EMS_GROUPID}/${EMS_ARTIFACTID}/${majv}_*/${EMS_ARTIFACTID}-${majv}_${minv}*.tar.gz&continuationToken=${continuationToken}\""
					eval ${cmd} >>nex_output
					continuationToken=$(grep 'continuationToken' nex_output | tail -1 | cut -d ':' -f 2 | tr -d ' ' | sed 's/\"//g')
				done				
                ver=`cat nex_output | grep -e "name" | grep "${EMS_ARTIFACTID}.*.tar.gz\"" | sort -n | tail -1 | cut -d '/' -f 3 | tr -d ' '`
                latestEMSVersion="$ver"
                echo "${latestEMSVersion}"
                ;;
        'SQL')
                echo "Implementation is in Progress!"
                ;;
        *)
                echo "ERROR: Please specify Valid option"
                ;;
esac