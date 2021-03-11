#!/bin/bash

# Kill verdaccio server
killall node

# Nuke all verdaccio packages
rm -rf ~/.local/share/verdaccio/
# And login stuff
rm ~/.config/verdaccio/htpasswd
