#!/bin/bash
# Add ref5 to the W6 spatial sweep, then re-analyse refs 2,3,4,5 vs reference ref6.
# Waits for the current w6sp sweep to finish (frees the 16 cores) before starting.
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs

echo "waiting for current w6 sweep (analysis + cores free)..."
while ! grep -q "Convergence rates" w6_spatial_pure.txt 2>/dev/null; do sleep 60; done
while pgrep -f "python poisson_energy.py" >/dev/null; do sleep 30; done
echo "cores free at $(date +%H:%M:%S)"

echo "=== W6 spatial ref 5 : start $(date +%H:%M:%S) ==="
mpiexec -n 16 python poisson_energy.py --williamson 6 --pure --degree 1 \
    --ref_level 5 --nsteps 256 --tmax 172800 --time_degree 2 --seed 987654321 \
    --no_output > logs/w6_spatial_ref5_ns256.log 2>&1 \
  && echo "[done] ref 5 $(date +%H:%M:%S)" || echo "[FAIL] ref 5"

echo "=== RE-ANALYSIS: refs 2,3,4,5 vs reference ref6 ==="
python scnv_analysis.py --williamson 6 --ref_levels 2 3 4 5 6 --nsteps 256 \
    --time_degree 2 --seeds 987654321 2>&1 | tee w6_spatial_pure.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
