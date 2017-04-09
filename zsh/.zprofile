# If we have don't have a display and we're on TTY1.
if [ -z "$DISPLAY" ] && [ -n "$XDG_VTNR" ] && [ "$XDG_VTNR" -eq 1 ]; then
    exec startx ~/.config/X11/xinitrc
fi
