#!/bin/bash
# Pure-vs-SFLT vorticity comparison panels (last snapshot, --tsidx -1).
# Run from the library clone (where the .pvd files from the run_w5_*/run_w6_* scripts are).
# Needs the vtk python module (no ParaView). Usage: bash make_panels.sh [path/to/this/scripts]
SCRIPTS_DIR="${1:-$(cd "$(dirname "$0")" && pwd)}"

# Fig. 11: Williamson 6, strong forcing, 2 days
python "$SCRIPTS_DIR/make_compare_figs.py" --pure w6_rsw_output_pure.pvd --sflt w6_rsw_output_SFLT_fig11.pvd \
    --field vorticity --tsidx -1 --out w6_fig11_vorticity_strong_forcing.png \
    --title "Williamson 6 vorticity at t=2 days, deterministic vs SFLT strong forcing"

# Fig. 19: Williamson 5, strong forcing, 5 days
python "$SCRIPTS_DIR/make_compare_figs.py" --pure w5_rsw_output_pure.pvd --sflt w5_rsw_output_SFLT_fig19strong.pvd \
    --field vorticity --tsidx -1 --out w5_fig19_strong_forcing.png

# The Fig. 10 (W6 mild) and mild Fig. 19 panels use the same call with the matching .pvd files
# (w6_rsw_output_{pure,SFLT}_fig10.pvd, w5_rsw_output_{pure_fig19,SFLT}.pvd); their exact
# titles/options were not recorded in a script.
