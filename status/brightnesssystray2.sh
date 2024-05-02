#!/bin/bash

icon_path="/usr/share/icons/usersprites/brightness-icon-md.png" # Update the icon path

# Persistent loop to handle the system tray icon
while true; do
    # Command to keep the icon in the systray and open the dialog on click
    yad --notification --image="$icon_path" \
        --command="bash -c '\
        while : ; do \
            current_brightness=\$(brightnessctl get 2>/dev/null); \
            max_brightness=\$(brightnessctl max 2>/dev/null); \
            brightness_percent=\$((current_brightness * 100 / max_brightness)); \
            command_output=\$(yad --title \"Brightness Control\" --width=300 --height=50 --posx=810 --posy=575 \
                --form --separator=\",\" --field=\"Set Brightness (0-100):NUM\" \"\$brightness_percent\"!0..100!1 \
                --button=\"Apply\":0 --button=\"Increase Brightness:1\" --button=\"Decrease Brightness:2\" --button=gtk-cancel:3 \
                --fixed --undecorated --on-top --skip-taskbar --skip-pager 2>/dev/null); \
            ret=\$?; \
            case \$ret in \
                0) \
                    new_brightness=\$(echo \$command_output | cut -d ',' -f 1); \
                    brightnessctl set \$new_brightness% > /dev/null 2>&1;; \
                1) \
                    brightnessctl set +10% > /dev/null 2>&1;; \
                2) \
                    brightnessctl set 10%- > /dev/null 2>&1;; \
                3) \
                    break;; \
                *) \
                    break;; \
            esac; \
        done'"
    
	# Sleep to ensure it doesn't respawn too quickly if closed
    sleep 0.5
done
