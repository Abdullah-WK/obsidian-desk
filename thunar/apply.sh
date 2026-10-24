#!/usr/bin/env bash
# Obsidian: Thunar settings (xfconf). Idempotent.
set -u
q() { xfconf-query -c thunar -p "$1" -n -t "$2" -s "$3"; }
q /last-view                            string ThunarDetailsView
q /last-menubar-visible                 bool   false
q /misc-full-path-in-title              bool   false
q /last-location-bar                    string ThunarLocationEntry
q /misc-single-click                    bool   false
q /last-details-view-visible-columns    string "THUNAR_COLUMN_NAME,THUNAR_COLUMN_SIZE,THUNAR_COLUMN_DATE_MODIFIED"
echo "thunar: settings applied (details view, menubar hidden: Ctrl+M shows it, location entry)"
