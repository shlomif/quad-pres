#!/bin/bash

find . -name '*.p[lm]' | xargs grep -h '^use' | 
    sort | uniq | 
    grep -v '^use \(Shlomif\|strict\|vars\|English\)'

