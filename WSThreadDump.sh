#!/bin/bash
# Script to do a stack trace of either WebSphere AppSrv01 or 02 when the CPU % goes over a threshold

threshold=25    # CPU usage threshold
duration=20     # Time to wait between thread dumps

get_SERVER() {  # Get the server name (AppSrv01 or 02) from the PID
    ps -ef | grep "$1" | grep wasuser | awk -F 'profiles/' '{print $2}' | awk -F '/' '{print $1}'
}
# Run top in batch mode to get CPU stats and PID
txt=`top -b -n 1 | grep wasuser | grep java | awk '{print $1, $9/32}'`
# Extract data from top command
pid1=`echo $txt | awk '{print $1}'`
cpu1=`echo $txt | awk '{print $2}'`
cpu1=${cpu1%.*}
svr1=$(get_SERVER ${pid1})
pid2=`echo $txt | awk '{print $3}'`
cpu2=`echo $txt | awk '{print $4}'`
cpu2=${cpu2%.*}
svr2=$(get_SERVER ${pid2})
#echo $svr1 $pid1 $cpu1
#echo $svr2 $pid2 $cpu2
if [[ ${cpu1} -gt ${threshold} ]]; then	# Do the thread dump for AppSrv01
	kill -3 $pid1
	sleep ${duration}
	kill -3 $pid1
	echo '<metric type="IntCounter" name="WebSphere|AppServer:AppSrv01 Thread Dump" value="1" />'
else
	echo '<metric type="IntCounter" name="WebSphere|AppServer:AppSrv01 Thread Dump" value="0" />'
fi
if [[ ${cpu2} -gt ${threshold} ]]; then # Do the thread dump for AppSrv02
	kill -3 $pid2
	sleep ${duration}
	kill -3 $pid2
	echo '<metric type="IntCounter" name="WebSphere|AppServer:AppSrv02 Thread Dump" value="1" />'
else
	echo '<metric type="IntCounter" name="WebSphere|AppServer:AppSrv02 Thread Dump" value="0" />'
fi
