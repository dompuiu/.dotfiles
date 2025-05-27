APP_NAME="$1"
RUNNING=$(osascript -e "tell application \"System Events\" to (name of processes) contains \"$APP_NAME\"")

if [ "$RUNNING" = "true" ]; then
  VISIBLE=$(osascript -e "tell application \"$APP_NAME\" to visible")
  if [ "$VISIBLE" = "true" ]; then
    osascript -e "tell application \"$APP_NAME\" to set visible to false"
  else
    osascript -e "tell application \"$APP_NAME\" to activate"
  fi
else
  open -a "$APP_NAME"
fi
