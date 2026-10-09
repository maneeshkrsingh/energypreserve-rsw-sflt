#!/bin/bash
# Temporal convergence vs EXACT (Lauter Ex.3), fixed fine mesh ref5 with quadratic
# geometry (coords_degree=2 -> low spatial floor), varying dt on a CFL-respecting
# ladder. cPG P1 (time_degree=1 == continuous P1 / P0 test == implicit midpoint).
# Courant C = u0*dt/h = 7.47/nsteps at ref5 (u0=38.6 m/s, h=223.2 km):
#   ns   8 -> C 0.93 | 16 -> 0.47 | 32 -> 0.23 | 64 -> 0.12 | 128 -> 0.06 | 256 -> 0.03
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs
REF=5; TMAX=43200; TDEG=1; SEED=987654321
NSTEPS="8 16 32 64 128 256"

for ns in $NSTEPS; do
  echo "=== temporal ref$REF nsteps $ns : start $(date +%H:%M:%S) ==="
  mpiexec -n 8 python poisson_energy.py --williamson 2 --pure \
      --ref_level $REF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/tcnv_coords2_ref${REF}_ns${ns}.log 2>&1 \
    && echo "[done] ns $ns $(date +%H:%M:%S)" || echo "[FAIL] ns $ns (see log)"
done

echo "=== ANALYSIS (vs exact) ==="
python exact_tcnv_analysis.py --williamson 2 --ref_level $REF --timesteps $NSTEPS \
    --tmax $TMAX --time_degree $TDEG --seed $SEED 2>&1 | tee lauter_temporal_coords2.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
