#!/bin/bash
# Williamson 6 (Rossby-Haurwitz) SPATIAL convergence, --pure. No exact solution ->
# finest mesh (ref6) is the numerical reference. degree=1 (coords=2 auto), cPG P2 in
# time so temporal error is negligible. tmax=2 days (pre-breakdown), nsteps=256
# (dt=675s, Courant ~0.3-0.5 at ref6). Test refs 2,3,4 vs ref6 -> two clean order-2 rates.
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs
TMAX=172800; SEED=987654321; DEG=1; WTC=6
MODE=${MODE:-spatial}             # spatial | temporal

if [ "$MODE" = "spatial" ]; then
  # SPATIAL: vary mesh at fixed dt; cPG P2 (TDEG=2) so the temporal error is negligible.
  TDEG=2; NS=256; REFS_TEST="2 3 4"; REF_FINE=6
  for r in $REF_FINE $REFS_TEST; do
    echo "=== W6 spatial ref $r : start $(date +%H:%M:%S) ==="
    mpiexec -n 16 python poisson_energy.py --williamson $WTC --pure --degree $DEG \
        --ref_level $r --nsteps $NS --tmax $TMAX --time_degree $TDEG --seed $SEED \
        --no_output > logs/w6_spatial_ref${r}_ns${NS}.log 2>&1 \
      && echo "[done] ref $r $(date +%H:%M:%S)" || echo "[FAIL] ref $r"
  done
  echo "=== ANALYSIS (scnv, reference = ref6) ==="
  python scnv_analysis.py --williamson $WTC --ref_levels $REFS_TEST $REF_FINE --nsteps $NS \
      --time_degree $TDEG --seeds $SEED 2>&1 | tee w6_spatial_pure.txt
else
  # TEMPORAL: fixed mesh ref5, vary dt vs a fine-dt NUMERICAL reference (ns=2560); cPG P1.
  TDEG=1; TREF=5; TNS="80 160 320 640 2560"
  for ns in $TNS; do
    echo "=== W6 temporal ref$TREF ns $ns : start $(date +%H:%M:%S) ==="
    mpiexec -n 16 python poisson_energy.py --williamson $WTC --pure --degree $DEG \
        --ref_level $TREF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
        --no_output > logs/w6_temporal_ref${TREF}_ns${ns}.log 2>&1 \
      && echo "[done] ns $ns $(date +%H:%M:%S)" || echo "[FAIL] ns $ns"
  done
  echo "=== ANALYSIS (tcnv, fine-dt numerical reference) ==="
  python tcnv_analysis.py --williamson $WTC --ref_level $TREF --seeds $SEED \
      --timesteps $TNS --tmax $TMAX --time_degree $TDEG 2>&1 | tee w6_temporal_pure.txt
fi
echo "=== ALL DONE $(date +%H:%M:%S) ==="
