#!/bin/bash

plottext() {
   cat <<EOF 
   "$1" using "TIMESTAMP":(\$4/\$5) with linespoints title "${1%.log}", \\
EOF
}

plotalltext() {
    cat <<EOF
    set title "$(basename `pwd`)"
    set output "$(basename `pwd`).png"
    set datafile separator "\t"
    set terminal pngcairo size 1200,700
    set xlabel "Date"
    set xdata time
    set timefmt "%Y-%m-%d %H:%M:%S"
    set ylabel "Speed (bytes / second)"
EOF
    echo -n "plot "
    for f in ./*.log; do
        plottext "$(basename "$f")"
    done
}

plotalltext | gnuplot
