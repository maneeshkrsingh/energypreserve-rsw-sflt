#!/bin/bash
# Temporal convergence, cPG P2 (time_degree=2), Lauter Ex.3 --pure, degree=2/coords=3.
# Fixed mesh ref3 (coarser -> larger stable dt -> more headroom above the numerical-
# reference floor) so the order-3 rate settles over >1 interval instead of flooring.
# vs fine-dt NUMERICAL reference (ns=256). Courant = 1.868/nsteps at ref3 (all < 0.9).
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs
TMAX=43200; SEED=987654321; DEG=2; TDEG=2; TREF=3
TNS="4 8 16 32 256"

for ns in $TNS; do
  echo "=== ref$TREF ns $ns deg$DEG tdeg$TDEG : start $(date +%H:%M:%S) ==="
  mpiexec -n 8 python poisson_energy.py --williamson 2 --pure --degree $DEG \
      --ref_level $TREF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/p2_temporal_ref${TREF}_ns${ns}.log 2>&1 \
    && echo "[done] ns $ns $(date +%H:%M:%S)" || echo "[FAIL] ns $ns"
done

echo "=== TEMPORAL ANALYSIS (numerical reference, cPG P2, ref3) ==="
python tcnv_analysis.py --williamson 2 --ref_level $TREF --seeds $SEED \
    --timesteps $TNS --tmax $TMAX --time_degree $TDEG 2>&1 \
  | tee lauter_temporal_p2_ref3.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
