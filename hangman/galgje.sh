#/bin/bash

## Script: galgje.sh
## Author: Arjen Wiersma
## Class: Linux hans on

## Globals ###########################################################

## There are 8 attempts + 1 start frame, thus 9 fames total
anim_count=9
## The graphic is 7 lines in height
anim_height=7
## default location of the dict file
dict_file=/usr/share/dict/words

debug=false

current_streak=0
alltime_high=0

dir=`dirname $0`

## Functions #########################################################

trap finish EXIT;

##
## read the current attempt from the current file
##
function get_current_streak() {
    current_streak=`cat $dir/current`
}

function get_alltime_high() {
    alltime_high=`cat $dir/highscore | head -1`
}

function write_current_streak() {
    echo $current_streak > $dir/current    
}

function write_high_score() {
    if [ $current_streak -gt 0 ]
    then
        score="$current_streak `whoami`"
        echo $score >> $dir/highscore
        mv $dir/highscore $dir/highscore2
        cat $dir/highscore2 | sort -rn | head -10 > $dir/highscore
        rm $dir/highscore2
    fi
}

##
## Exit function to make sure highscores are preserved
##
function finish() {
    write_current_streak
    write_high_score
    echo "GoodBye!"
}

##
## Render a frame from the graphics.txt file
##
function render_frame() {
    frame_id=$1
    # Where do we start looking for the current frame
    offset=$((frame_id * anim_height))

    echo "Current streak: " $current_streak " all time high: " $alltime_high
    cat graphics.txt | head -n $offset | tail -n $anim_height
}

##
## Print the usage of the program
##
function print_usage() {
    echo "Galgje - made by Arjen Wiersma - usage"
    echo "	-f ARG	Dictorionary file to use, default" $dict_file
    echo "	-h	This message"
}

##
## Select a word from the dictorionary list
##
function select_word() {
    sw_count=$(wc -l $dict_file | cut -f1 -d" ")
    # Limitation: RANDOM only goes to 32767
    sw_select=$(( $RANDOM % $sw_count ))

    echo -n $( cat $dict_file | head -n $sw_select | tail -n 1 )
}

##
## A single game of hangman
##
function game() {
    g_word=$1
    g_upper_word=$(echo -n $g_word | tr '[a-z]' '[A-Z]')
    g_masked=$(echo -n $g_upper_word | tr '[A-Z]' '-')

    get_current_streak
    get_alltime_high

    busy=true

    guessed=""
    attempts=8
    g_frame_id=1

    while $busy
    do
        clear
        if [ true == $debug ] 
        then 
            echo "DEBUG: word is " $g_word
        fi
        render_frame $g_frame_id

        ## WINNER
        if [ $g_masked = $g_upper_word ]
        then
            echo "Gefeliciteerd! Je hebt het woord geraden!"
            current_streak=$((current_streak+1))
            write_current_streak
            write_high_score
            sleep 3
            break
        elif [ $attempts -eq 0 ]; then
            # End of life!
            echo "Helaas, alle pogingen zijn op!"
            echo "Het woord was: " $g_word
            write_high_score
            current_streak=0
            write_current_streak
            sleep 3
            break
        fi

        echo "Huidige stand: " $g_masked
        echo "Pogingen over: " $attempts " Gebruikte letters: " $guessed
        echo -n "Voer een letter of het gehele woord in: "
        read input

        input=$(echo -n $input | tr '[a-z]' '[A-Z]')
        # 1 letter invoer
        if [ $(echo -n $input | wc -c) = 1 ]
        then
            case $input in
                [A-Z])
                    if [[ "$guessed" == *"$input"* ]]
                    then
		 	# Beter in een losse function?
                        echo "Deze letter is al eens gebruikt!"
                        attempts=$((attempts - 1))
                        g_frame_id=$((g_frame_id + 1))
                        sleep 1
                    elif [[ "$g_upper_word" == *"$input"* ]]
                    then
                        guessed=$guessed$input
                        g_masked=$(echo -n $g_upper_word | tr -c $guessed '-')
                    else
                        echo "Incorrect! Je verliest een poging"
                        guessed=$guessed$input
                        attempts=$((attempts - 1))
                        g_frame_id=$((g_frame_id + 1))
                        sleep 1
                    fi
                    ;;
                *)
                    echo "Foute invoer: " $input
                    ;;
            esac
        elif [ $(echo -n $input | wc -c) = $(echo -n $g_upper_word | wc -c) ]
	then
	    case $input in
		$g_upper_word)
			guessed=$input
                        g_masked=$(echo -n $g_upper_word | tr -c $guessed '-')
			;;
		*)
			echo "Fout woord opgegeven, u verliest een beurt"
                        attempts=$((attempts - 1))
                        g_frame_id=$((g_frame_id + 1))
			sleep 1
			;;
	    esac
	else
	    echo "U heeft iets fouts opgegeven, probeer het nog maals; raad een letter of het woord!"
	    sleep 1
        fi
    done
}

## Program ###########################################################

## Get the command line arguments
while getopts ":f:h:d" opt; do
    case $opt in
        f)
            echo "Using dictionary file $OPTARG" >&2
            dict_file=$OPTARG
            ;;
        h)
            print_usage
            exit 1
            ;;
        d)
            debug=true
            ;;
        :)
            echo "Option -$OPTARG requires an argument"
            print_usage
            exit 1
            ;;
    esac
done

## Show a menu that allows to start the game

while true
do
    clear
    echo "Galgje - door Arjen Wiersma"
    echo 
    echo "Spel opties:"
    echo "	0. Het spel afsluiten"
    echo "	1. Start het spel"
    echo "	2. Highscores"
    echo -n "Uw keuze: "
    
    read keuze

    case $keuze in
        0)
            echo "Bedankt voor het spelen, tot ziens!"
            exit 0
            ;;
        1)
            game "$(select_word)"
            ;;
        *)
            clear
            echo "Galgje - Highscores - door Arjen Wiersma"
            echo
            echo
            cat $dir/highscore
            echo
            echo "Druk op een toets"
            read
            ;;
    esac
done
