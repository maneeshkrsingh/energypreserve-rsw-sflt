#!/bin/bash
# Degree-robustness convergence study, Lauter Ex.3 --pure.
#   degree=2 (BDM3/DG2), coords_degree=3 (auto = degree+1), time_degree=2 (cPG P2).
# Expect SPATIAL order ~3 (both u,D) and TEMPORAL order ~4.
# Spatial: vary mesh at fixed dt (time_degree=2 makes temporal error negligible).
# Temporal: fixed mesh, vary dt, vs fine-dt NUMERICAL reference (degree-agnostic, no floor).
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs
TMAX=43200; SEED=987654321; DEG=2; TDEG=2

# ---------- SPATIAL: refs 2,3,4 at nsteps=1000 ----------
SPATIAL_REFS="2 3 4"; SNS=1000
for r in $SPATIAL_REFS; do
  echo "=== [spatial] ref $r deg$DEG tdeg$TDEG : start $(date +%H:%M:%S) ==="
  mpiexec -n 8 python poisson_energy.py --williamson 2 --pure --degree $DEG \
      --ref_level $r --nsteps $SNS --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/deg2_spatial_ref${r}_ns${SNS}.log 2>&1 \
    && echo "[done] spatial ref $r $(date +%H:%M:%S)" || echo "[FAIL] spatial ref $r"
done

# ---------- TEMPORAL: ref4, vary dt, ns=256 is the fine reference ----------
TREF=4; TNS="8 16 32 64 256"
for ns in $TNS; do
  echo "=== [temporal] ref$TREF ns $ns deg$DEG tdeg$TDEG : start $(date +%H:%M:%S) ==="
  mpiexec -n 8 python poisson_energy.py --williamson 2 --pure --degree $DEG \
      --ref_level $TREF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/deg2_temporal_ref${TREF}_ns${ns}.log 2>&1 \
    && echo "[done] temporal ns $ns $(date +%H:%M:%S)" || echo "[FAIL] temporal ns $ns"
done

echo "=== SPATIAL ANALYSIS (vs exact, degree=$DEG) ==="
python exact_cnv_analysis.py --williamson 2 --ref_levels $SPATIAL_REFS --nsteps $SNS \
    --tmax $TMAX --time_degree $TDEG --degree $DEG --seed $SEED 2>&1 \
  | tee lauter_spatial_deg2.txt

echo "=== TEMPORAL ANALYSIS (numerical reference, degree=$DEG) ==="
python tcnv_analysis.py --williamson 2 --ref_level $TREF --seeds $SEED \
    --timesteps $TNS --tmax $TMAX --time_degree $TDEG 2>&1 \
  | tee lauter_temporal_deg2.txt

echo "=== ALL DONE $(date +%H:%M:%S) ==="
