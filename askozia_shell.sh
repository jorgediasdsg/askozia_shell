#!/bin/bash
#
#   Askozia Shell
#
#   Author Jorge Dias - jorgediasdsg@gmail.com
#
#   Script para monitorar quem loga e desloga da fila do askozia.
#
#   Versão 0.1 - Refeito em Shell a aplicação anteriormente feira em nodeJS.
#
ASKOZIA_GET_ALL_EXTENSIONS="<API_ASKOZIA>"
ASKOZIA_QUEUE_SHOW_STATUS="<API_ASKOZIA>"
ROCKETCHAT_URL="<API_ROCKETCHAT>"

msg(){
    ALL_LINES=`curl $ASKOZIA_GET_ALL_EXTENSIONS`
    FIND=`echo "$2" | sed "s/\"// ; s/\"//"`
    echo $FIND
    DESCR=$(echo $ALL_LINES | jq ".[].descr" | grep $FIND)
    DATA=`date +%F-%A-%Hh%Mm%Ss`
    MSG="$1 $DESCR em $DATA"
    MSG=`echo $MSG | sed "s/\"// ; s/\"//"`
    echo $MSG
    curl -X POST -H "Content-Type: application/json" --data "{\
        \"text\": \"$MSG\"\
        }"\
    $ROCKETCHAT_URL
}

while :
    do
    LOAD_LINE=`curl $ASKOZIA_QUEUE_SHOW_STATUS`
    N_LINE_ARRAY=()
    add_news(){
        for i in $(seq 0 10); do
            USER=$(echo $LOAD_LINE  | jq ".agents[$i]")
            ONLINE=0
            if [[ $USER != "null" ]]; then
                N_AGENT_LINE=$(echo $LOAD_LINE  | jq ".agents[$i].extension")
                N_AGENT_CALLS_TODAY=$(echo $LOAD_LINE  | jq ".agents[$i].calls_today")
                N_AGENT_LAST_CALL=$(echo $LOAD_LINE  | jq ".agents[$i].last_call")

                N_LINE_ARRAY+=( $N_AGENT_LINE )

                for ((I=0;I<10;I++)); do 
                    if [[ ${O_LINE_ARRAY[${I}]} == $N_AGENT_LINE ]]; then
                        echo "LINE $N_AGENT_LINE ONLINE"
                        ONLINE=1
                    fi
                done
                if [[ $ONLINE == 0 ]]; then
                    echo "LINE $N_AGENT_LINE OFFLINE"
                    O_LINE_ARRAY+=( $N_AGENT_LINE )
                    msg ":arrow_up_small: Entrou" "$N_AGENT_LINE"
                fi
            fi
        done
    }
    remove_outs(){
        OLD=${!O_LINE_ARRAY[@]}
        NEW=${!N_LINE_ARRAY[@]}
        for old_int in $OLD; do
            OLD_USER_ONLINE=0
            for new_int in $NEW; do
                if [[ ${O_LINE_ARRAY[$old_int]} == ${N_LINE_ARRAY[$old_int]} ]]; then
                    OLD_USER_ONLINE=1
                fi
            done
            if [[ $OLD_USER_ONLINE == 0 ]]; then
                echo "${O_LINE_ARRAY[$old_int]} Saiu!"
                msg ":arrow_down_small: Saiu " "${O_LINE_ARRAY[$old_int]}"
                unset O_LINE_ARRAY[$old_int]
            fi
        done
    }
        add_news
        remove_outs
        echo "NEW ${N_LINE_ARRAY[@]} | OLD ${O_LINE_ARRAY[@]}"
   sleep 2
done
