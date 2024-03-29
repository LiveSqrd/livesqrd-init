#!/bin/sh
APP_DIR="/var/www/lsq-server"
NODE_APP="app.js"
PID_DIR="/var/run/lsq"
PID_FILE="$PID_DIR/lsq-server.pid"
LOG_DIR="/var/log/lsq"
LOG_FILE="$LOG_DIR/lsq-server.log"
NODE_EXEC=$(which node)

###############

# REDHAT chkconfig header

# chkconfig: - 58 74
# description: node-app is the script for starting a node app on boot.
### BEGIN INIT INFO
# Provides: node
# Required-Start:    $network $remote_fs $local_fs
# Required-Stop:     $network $remote_fs $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start and stop node
# Description: Node process for app
### END INIT INFO

###############

USAGE="Usage: $0 {start|stop|restart|status} [--force]"
FORCE_OP=false

pid_file_exists() {
    [ -f "$PID_FILE" ]
}

get_pid() {
    echo "$(cat "$PID_FILE")"
}

is_running() {
    PID=$(get_pid)
    ! [ -z "$(ps aux | awk '{print $2}' | grep "^$PID$")" ]
}

# start_it() {
#     mkdir -p "$PID_DIR"
#     mkdir -p "$LOG_DIR"

#     echo "Starting node app ..."
#     echo "$NODE_EXEC"
#     $NODE_EXEC "$APP_DIR/$NODE_APP"  1>"$LOG_FILE" 2>&1 &
#     echo $! > "$PID_FILE"
#     echo "Node app started with pid $!"
# }

start_it() {
    mkdir -p "$PID_DIR"
    mkdir -p "$LOG_DIR"

    echo "Starting node app ..."
    forever start -l "$LOG_FILE" -a --pidFile "$PID_FILE" -m 10 "$APP_DIR/$NODE_APP" 
}
stop_process() {
    #PID=$(get_pid)
    echo "Killing process $APP_DIR/$NODE_APP"
    forever stop "$APP_DIR/$NODE_APP"
}

remove_pid_file() {
    echo "Removing pid file"
    rm -f "$PID_FILE"
}

start_app() {
    if pid_file_exists
    then
        if is_running
        then
            PID=$(get_pid)
            echo "Node app already running with pid $PID"
            exit 1
        else
            echo "Node app stopped, but pid file exists"
            if [ $FORCE_OP = true ]
            then
                echo "Forcing start anyways"
                remove_pid_file
                start_it
            fi
        fi
    else
    export NVM_DIR="/home/ubuntu/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
        start_it
    fi
}

stop_app() {
    if pid_file_exists
    then
        if is_running
        then
            echo "Stopping node app ..."
            stop_process
            #remove_pid_file
            echo "Node app stopped"
        else
            echo "Node app already stopped, but pid file exists"
            if [ $FORCE_OP = true ]
            then
                echo "Forcing stop anyways ..."
                remove_pid_file
                echo "Node app stopped"
            else
                exit 1
            fi
        fi
    else
        echo "Node app already stopped, pid file does not exist"
        exit 1
    fi
}

status_app() {
    if pid_file_exists
    then
        if is_running
        then
            PID=$(get_pid)
            echo "Node app running with pid $PID"
        else
            echo "Node app stopped, but pid file exists"
        fi
    else
        echo "Node app stopped"
    fi
}

case "$2" in
    --force)
        FORCE_OP=true
    ;;

    "")
    ;;

    *)
        echo $USAGE
        exit 1
    ;;
esac

case "$1" in
    start)
        start_app
    ;;

    stop)
        stop_app
    ;;

    restart)
        stop_app
        start_app
    ;;

    status)
        status_app
    ;;

    *)
        echo $USAGE
        exit 1
    ;;
esac