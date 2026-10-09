#!/bin/bash
# Temporal convergence, cPG P1 (time_degree=1), Lauter Ex.3 --pure, degree=1 (standard
# production discretisation, coords=2). FINER mesh ref5 (small mesh width h) so the
# spatial error floor is low and the order-2 temporal convergence shows cleanly vs the
# EXACT solution. tmax=5 days. Courant = u0*dt/h5 = 38.6*dt/223200 at ref5:
# ns160->0.47, 320->0.23, 640->0.12, 1280->0.06 (ns80 would be ~0.93 -> dropped).
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs
TMAX=432000; SEED=987654321; DEG=1; TDEG=1; TREF=5
TNS="160 320 640 1280"

for ns in $TNS; do
  echo "=== ref$TREF ns $ns tmax15d : start $(date +%H:%M:%S) ==="
  mpiexec -n 16 python poisson_energy.py --williamson 2 --pure --degree $DEG \
      --ref_level $TREF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/p1_5day_ref${TREF}_ns${ns}.log 2>&1 \
    && echo "[done] ns $ns $(date +%H:%M:%S)" || echo "[FAIL] ns $ns"
done

echo "=== TEMPORAL ANALYSIS (cPG P1, ref5, degree1, vs exact) ==="
python exact_tcnv_analysis.py --williamson 2 --ref_level $TREF --timesteps $TNS \
    --tmax $TMAX --time_degree $TDEG --degree $DEG --seed $SEED 2>&1 \
  | tee lauter_temporal_p1_ref5.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
