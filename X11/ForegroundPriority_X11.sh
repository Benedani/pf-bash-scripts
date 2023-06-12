prevpid=a
while true; do
  currentpid=$(xdotool getactivewindow getwindowpid)

  if [[ "$currentpid" =~ ^[0-9]+$ ]]; then
    if [[ $currentpid != $prevpid ]]; then
      if [[ "$prevpid" =~ ^[0-9]+$ ]]; then
        # Set idle/idle on previous process
        #echo "Idling $prevpid"
        #chrt --idle --pid 0 $prevpid
        ionice -c 0 -p $prevpid
        renice -n 0 -p $prevpid
      fi

      # Set round robin/realtime on current process
      #echo "Setting $currentpid"
      #chrt --rr --pid 99 $currentpid
      ionice -c 2 -p $currentpid
      renice -n -20 -p $currentpid

      # The desktop processes should always have high priority
      movpid=$(pgrep kwin_x11)
      #chrt --rr --pid 99 $movpid
      renice -n -20 -p $movpid
      movpid=$(pgrep plasmashell)
      #chrt --rr --pid 99 $movpid
      renice -n -20 -p $movpid
      movpid=$(pgrep Xorg)
      #chrt --rr --pid 99 $movpid
      renice -n -20 -p $movpid

      prevpid=$currentpid
    fi
  fi
  sleep 0.1
done
