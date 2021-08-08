#!/bin/bash
cat $1 | jq '[.packages | del(."") | .[] | select(
  (has("link") == false) and 
  (has("dev") == false) and 
  (has("optional") == false) and 
  (has("devOptional") == false))] | length'