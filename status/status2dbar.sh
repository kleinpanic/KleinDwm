#!/bin/bash
##Global Definitions

#Color definitions
color_black="#000000" #outline
color_white="#ffffff" #default
color_green="#00ff00"
color_yellow="#ffff00"
color_red="#ff0000" 
color_grey="#555555"

#Primary scheme - medium orchid
color_scheme_1="#c067dd" #background 
color_scheme_2="#a656c2" 
color_scheme_3="#8B45A7"
color_scheme_4="#71348C" #highlight
color_scheme_5="#572371"
color_scheme_6="#3C1256" 
color_scheme_7="#22013B" #default text color

#Complimentary scheme - pastel green
c_color_scheme_1="#84dd67" #Complimentary background color
c_color_scheme_2="#72c059"
c_color_scheme_3="#60a44b"
c_color_scheme_4="#4f883d" #Complimentary highlight
c_color_scheme_5="#3f6e30"
c_color_scheme_6="#2f5523"
c_color_scheme_7="#203d17" #Complimentary txt color


get_date() {
    # Define base colors
    local color=$color_scheme_7  # Default color for the date text
    local bg_color=$color_grey  # Background color for the rectangle
    local fill_color="#00FF00"  # Fill color for the rectangle

    # Day of the week (1 = Monday, ..., 7 = Sunday)
    local day_of_week=$(date +"%u")
    local date_info=$(date +"%-m/%-d %H:%M")  # Current date and time

    # Define dimensions for the fill bar
    local base_x=0
    local base_y=20
    local max_height=8
    local bar_width=5

    # Calculate the height of the fill bar based on the day of the week
    # Day 7 (Sunday) will be empty, day 6 (Saturday) will be full
    local fill_height=$(( (7 - day_of_week) * 3 ))

    # Initialize the status line with date information
    local status_line="$date_info"

    # Append background rectangle for 100% capacity
    status_line+="^c$bg_color^^r$base_x,$((base_y - max_height)),$bar_width,$max_height^"

    # Calculate top y-coordinate for the fill rectangle
    local upper_y=$((base_y - fill_height))

    # Append active usage bar on top of the background
    status_line+="^c$fill_color^^r$base_x,$upper_y,$bar_width,$fill_height^"
	status_line+="^d^^f5^"
    # Reset the drawing colors and output the status line
    echo "[$status_line]"
}	

get_cpu() { 
	local cpu_stats=$(top -bn1 | grep "%Cpu(s)") #Capture top's CPU line.
    # Extract CPU state percentages using awk
    local us=$(echo $cpu_stats | awk '{print $2}' | tr -d '%')
    local sy=$(echo $cpu_stats | awk '{print $4}' | tr -d '%')
    local ni=$(echo $cpu_stats | awk '{print $6}' | tr -d '%')
    local id=$(echo $cpu_stats | awk '{print $8}' | tr -d '%')
    local wa=$(echo $cpu_stats | awk '{print $10}' | tr -d '%')
    local hi=$(echo $cpu_stats | awk '{print $12}' | tr -d '%')
    local si=$(echo $cpu_stats | awk '{print $14}' | tr -d '%')
    local st=$(echo $cpu_stats | awk '{print $16}' | tr -d '%')
	
	#TopCon
	local top_cpu_consumer=$( ps -eo %cpu,comm --sort=-%cpu | head -n 2 | tail -n 1 | awk '{print $2}')
	top_cpu_consumer="${top_cpu_consumer:0:8}"
	#Base settings for drawing
	local base_x=0
	local base_y=20
	local max_height=16
	local bar_width=5
	local status_line=""
	local bg=$color_grey

	# Define colors for each state
    declare -A colors=( [us]="#ffd700" [sy]="#ff4500" [ni]="#ff8c00" [id]="#008000"
                        [wa]="#0000ff" [hi]="#4b0082" [si]="#800080" [st]="#a0522d" )
	
	# Create a vertical bar for each CPU state
    for state in us sy ni id wa hi si st; do
        local percentage=$(echo ${!state})  # Get the percentage directly
        # Safeguard against malformed input
        if [[ ! "$percentage" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
			#echo "Error: Invalid percentage value for $state - '$percentage'. Setting to 0." >&2
            percentage=0
        fi

		local bar_height=$(echo "$percentage * $max_height / 100" | bc)  # Calculate bar height
		
		#Draw active bacground rectangle for 100% capacity
		status_line+="^c$bg^^r${base_x},$((base_y - max_height)),${bar_width},${max_height}^"
		
		#Draw active usage bar on top of the background
		local upper_y=$((base_y - bar_height))  # Calculate the top y-coordinate of the bar
        status_line+="^c${colors[$state]}^^r$base_x,$upper_y,$bar_width,$bar_height^"
        base_x=$((base_x + bar_width + 2))  # Move x for the next bar
    done

	# Reset formatting and forward
    status_line+="^d^^f54^"

	echo "[$status_line$top_cpu_consumer]"
} 

get_ram() { 
	# Get memory usage from the 'free' command (values in MB)
    local mem_info=$(free -m)
    local total_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $2}')
    local used_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $3}')

	# Calculate percentage of memory used
    local mem_usage=$(awk "BEGIN {printf \"%.0f\", ($used_mem/$total_mem)*100}")

    # Base settings for the status bar icon
    local max_width=30  # Maximum width of the RAM usage bar
    local bar_width=$((max_width * mem_usage / 100))  # Scale bar width by memory usage
    local bar_height=10
    local base_x=0
    local base_y=5
    local color=$color_white
	local border=$color_black
	local bg=$color_grey

	# Build the status2d string
    local status_line=""
	status_line+="^c$bg^"  # Start bg color tag
	status_line+="^r$base_x,$base_y,$((max_width + 2)),$((bar_height + 2))^" #bg rect
	#draw the fill baw
	status_line+="^c$color^"
	status_line+="^r$((base_x + 1)),$((base_y + 1)),${bar_width},${bar_height}^"
    status_line+="^d^^f30^"  # Reset drawing colors

    # Display RAM usage as text next to the bar (optional)
    status_line+="${mem_usage}%"

	echo "[$status_line]"
} 

get_df() {
    # Fetch disk usage data
    local disk_data=$(df -h | grep -E '/dev/nvme0n1p7|/dev/nvme0n1p9|/dev/nvme0n1p1')
    
    # Base settings for drawing
    local base_x=0
    local base_y=20
    local max_height=16
    local bar_width=5
    local status_line=""
    local bg=$color_grey

    # Define colors for each partition
    declare -A colore=(
        ["/dev/nvme0n1p7"]="#FFD700"
        ["/dev/nvme0n1p9"]="#FF4500"
        ["/dev/nvme0n1p1"]="#FF8C00"
    )

    # Process each partition line
    while read -r line; do
        local filesystem=$(echo $line | awk '{print $1}')
        local used=$(echo $line | awk '{print $3}')
        local total=$(echo $line | awk '{print $2}')
        local usage_percent=$(echo $line | awk '{print $5}' | tr -d '%')
		if [[ ! "$usage_percent" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
			usage_percentage=0
        fi

		# Calculate the bar height
        local bar_height=$(echo "$usage_percent * $max_height / 100" | bc)
        
        # Draw the background rectangle for 100% capacity
        status_line+="^c$bg^^r${base_x},$((base_y - max_height)),${bar_width},${max_height}^"
        
        # Draw the usage bar on top of the background
        local upper_y=$((base_y - bar_height))
        status_line+="^c${colore[$filesystem]}^^r$base_x,$upper_y,$bar_width,$bar_height^"
        # Move x for the next bar
        base_x=$((base_x + bar_width + 2))
    done <<< "$disk_data"

    # Reset formatting and move forward
    status_line+="^d^^f19^"

    echo "[$status_line]"
}

get_temperature() {
	local temp=$(sensors | awk '/Package id 0/ {gsub(/[^0-9.]/, "", $4); print int($4)}') 
	local max_temp=100
	
	#color
	local color=$color_white
	local bg=$color_scheme_1
	local outline=$color_black
	
	if [ "$temp" -gt "$max_temp" ]; then 
		color=$color_red 
	elif [ "$temp" -lt "$max_temp" ]; then 
		color=$color_green
	fi 
	
	#Temp icon
	# Calc fill height based on current temp
	local fill_height=$(($temp * 10 / $max_temp )) #Scale factor for height (0-100c)
	#Base Y
	local base_y=5 #lower number = higher
	# Build the temperature icon
	local temp_icon="^c$outline^" # outline color for the thermometer
	temp_icon+="^r5,$base_y,4,11^" #Outer rectangl for the thermometer 
	temp_icon+="^c$bg^" #background color for the thermometer
	temp_icon+="^r6,$((base_y + 1)),2,9^" #background inner tectangle
	temp_icon+="^c$color^"
	temp_icon+="^r6,$((base_y + 8 - fill_height)),2,$fill_height^" #filled part of the icon
	temp_icon+="^c$outline^" # reset to outline color for the bulb
	temp_icon+="^r4,$((base_y + 9)),7,4^" #small circle/ellipse for the bulb at the bottom
	temp_icon+="^r5,$((base_y + 10)),5,4^" #bottomg part of the bulb
	temp_icon+="^d^^f10^" #Reset to default color
	echo "^c$color_black^[^d^$temp_icon $temp°C^c$color_black^]^d^"
}

get_battery() {
	local status=$(cat /sys/class/power_supply/BAT0/status)
	local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
	local current_now=$(cat /sys/class/power_supply/BAT0/current_now)
	local voltage_now=$(cat /sys/class/power_supply/BAT0/voltage_now)
	local power_consumption=$(awk "BEGIN {printf \"%.2f\n\", ($current_now/1000000)*($voltage_now/1000000)}")

	local color=$color_scheme_7
	local bg=$color_scheme_1
	local outline=$color_black
	local color_status=$color_white


	# Set color based on battery status
	if [[ "$capacity" -le 15 ]]; then
		color=$color_red
	elif [[ "$capacity" -le 25 ]]; then
		color=$color_yellow
	else
		color=$color_green
	fi

	#Calc the width of the battery fill based on percentage
	local fill_width=$(($capacity * 20 / 100)) 
	#y cordinate 
	local base_y=7 #increase to lower shift
	#Dynamic test
	local battery_icon="^c$outline^"             # Outline color
	battery_icon+="^r2,$base_y,22,10^"                 # Outer Rectangle of the battery
	battery_icon+="^c$bg^"                             # Background color for the empty part
	battery_icon+="^r3,$((base_y +1)),20,8^"           # Background for the battery icon 
	battery_icon+="^c$color^" 
	battery_icon+="^r3,$((base_y + 1)),$fill_width,8^" # Filled part of the battery
	battery_icon+="^c$outline^"                  # Reset color for the bump   
	battery_icon+="^r0,$((base_y + 3)),2,4^"           # Battery Bump
	battery_icon+="^d^^f24^"                           # End and forward
	#Draw battery (Static and works) 
	#local battery_icon="^r0,7,2,4^^r2,4,22,10^^c$color^^r3,5,20,8^^c$bg^^r10,5,13,8^^d^^f24^"

	if [[ "$status" == "Full" ]]; then
		status="F"
		color_status=$color_green
	elif [[ "$status" == "Charging" ]]; then
		status="C"
		color_status=$c_color_scheme_1
	elif [[ "$status" == "Discharging" ]]; then
		status="D"
		color_status=$color_yellow
	elif [[ "$status" == "Not charging" ]]; then
		status="NC"
		color_status=$color_scheme_4
	else
		status="NA"
	fi

	echo "[$battery_icon^c$color^$capacity^d^%]" 
}

get_wifi() { 
	local color=$color_black
	local bg=$color_grey
	local ssid=$(iwgetid -r)
	ssid="${ssid:-No WiFi}"
	ssid="${ssid:0:15}"
	
	# -30 dBm (excellent) to -90 dBm (poor) 
	local dwm=$(grep wlp0s20f3 /proc/net/wireless | awk '{ print int($4) }')
	local signal_normalized=$(( (dwm + 90) * 100 / 60 )) #Maps -90 dBm = 0%, -30 dBm = 100%.
	#clamp the signal_normalized to a 0-100 range for percentages. 
	local signal
	if [ $signal_normalized -gt 100 ]; then
		signal=100
	elif [ $signal_normalized -lt 0 ]; then
		signal=0
	else 
		signal=$signal_normalized
	fi
	
	#color controll
	local color=$color_white
	if [ $signal -ge 66 ]; then
		color=$color_green
	elif [ $signal -le 33 ]; then
		color=$color_red
	elif [ $signal -gt 33 ] && [ $signal -lt 66 ]; then
		color=$color_yellow
	fi
	#Define base coordinates and size for WiFi icons
	local base_x=0
	local base_y=20
	local max_bars=5
	local bars_filled=$((signal / 20))

	# Building the WiFi signal icon
	local wifi_icon="^c$color^"
	for i in 1 2 3 4 5; do
		local width=$((3 * i + 1))
		local height=$((3 * i + 1))
		local height_placement=$((base_y - height))
		if [ $i -le $bars_filled ]; then
			wifi_icon+="^c$color^"
		else 
			wifi_icon+="^c$bg^"
		fi
		wifi_icon+="^r$((base_x + 3 * (i - 1))),$height_placement,$width,$height^"
	done
	wifi_icon+="^d^^f18^" 
	

	echo "[$wifi_icon$ssid[$signal%]]"
} 

# Get the width of the screen in characters
get_screen_width() {
    local screen_width_px=$(xdpyinfo | awk '/dimensions:/ {print $2}' | cut -dx -f1)
	echo $((screen_width_px / 1)) # Average character in px (calced by 1920/9.06=212)
}  

# Main status bar function using associative array
get_status() {
    local screen_width=$(get_screen_width)  # Get the screen width in characters
	declare -A components=(
        [date]="$(get_date)"
        [cpu]="$(get_cpu)"
        [ram]="$(get_ram)"
        [df]="$(get_df)"
        [temperature]="$(get_temperature)"
        [battery]="$(get_battery)"
        [wifi]="$(get_wifi)"
    )
    local status_line=""
    local separator=""
    local total_length=0
	local sep_length=${#separator}
	#echo "Sep_Length: $sep_length" >&2

	# Build the status line from right to left
    for component in date wifi battery temperature df ram cpu; do
		local component_output="${components[$component]}"
		local component_length=$(( ${#component_output} + sep_length ))
		# Debugging output to stderr for terminal viewing
        #echo "Adding component: $component" >&2
        #echo "Component output length: ${#component_output}" >&2
        #echo "Component length with separator: $component_length" >&2
        #echo "Total length before adding: $total_length" >&2
        #echo "Total after adding if allowed: $((total_length + component_length))" >&2
        #echo "Screen width: $screen_width" >&2
		

		if [[ $((total_length + component_length)) -le $screen_width ]]; then
			status_line="${component_output}${status_line}"
            total_length=$((total_length + component_length))
            #echo "total length after check $total_length" >&2
		else
			echo "Skipped: $component due to space constraints"
		fi
	done

    echo "$status_line"
}



while true 
do
    # Capture the output of get_status into a variable
	xsetroot -name "$(get_status)"
    # Wait for 5 seconds before updating again
    sleep 1
done



