#!/bin/bash
# Deterministic (--pure) convergence study for the Läuter Ex.3 manufactured solution.
# Spatial sweep (fixed small dt, vary mesh) + temporal sweep (fixed fine mesh, vary dt),
# then error-vs-exact analysis for both.  Intended to be launched in tmux:
#     tmux new -s lauter
#     bash run_lauter_determ.sh
# Re-running is cheap: completed checkpoints are reused (set RERUN=1 to force re-solve).

[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving

# -------------------- knobs --------------------
NP=8                       # MPI ranks per run
WTC=2                      # testcase id (Läuter Ex.3 = --williamson 2)
TMAX=43200                 # final time [s]  (12 h; exact-solution period = 1 day = 86400 s)
TDEG=1                     # cPG time degree
SEED=987654321             # matches sw_tools default

# spatial: fixed small dt (large nsteps so temporal error is negligible vs spatial)
# nsteps=2000 (dt=21.6s at tmax=43200) keeps the temporal floor ~4x below the ns=1000
# level, so the velocity rate (expected ~1.5) is not suppressed at the finest mesh.
SPATIAL_REFS="2 3 4 5"
SPATIAL_NSTEPS=2000

# temporal: fixed fine mesh (so spatial error is negligible vs temporal)
TEMPORAL_REF=5
TEMPORAL_NSTEPS="25 50 100 200 400 800"

RERUN=${RERUN:-0}          # 1 = ignore existing checkpoints and re-solve
BDFM=${BDFM:-0}            # 1 = BDFM velocity space (else BDM). Use RERUN=1 when switching family.
DO_TEMPORAL=${DO_TEMPORAL:-1}   # 0 = spatial sweep + analysis only
FAM_FLAG=""; FSUF="bdm"
[ "$BDFM" = "1" ] && { FAM_FLAG="--bdfm"; FSUF="bdfm"; }
CHK="../RSW_checkpoint/new_RSW_checkpoint"
mkdir -p logs
# -----------------------------------------------

run_one () {   # args: ref nsteps
  local r=$1 ns=$2
  local ckpt="${CHK}/velocity_timestepping_w${WTC}_${r}_${ns}_pure_tdeg${TDEG}_seed${SEED}.h5"
  local log="logs/pure_ref${r}_ns${ns}.log"
  if [[ -f "$ckpt" && "$RERUN" != "1" ]]; then
    echo "[skip] ref $r nsteps $ns  (checkpoint exists)"
    return
  fi
  echo "[run ] ref $r nsteps $ns  -> $log"
  mpiexec -n $NP python poisson_energy.py --williamson $WTC --pure $FAM_FLAG \
      --ref_level $r --nsteps $ns --tmax $TMAX \
      --time_degree $TDEG --seed $SEED --no_output > "$log" 2>&1 \
    && echo "[done] ref $r nsteps $ns" \
    || echo "[FAIL] ref $r nsteps $ns  (see $log)"
}

echo "############ SPATIAL sweep (pure): refs [$SPATIAL_REFS] at nsteps=$SPATIAL_NSTEPS ############"
for r in $SPATIAL_REFS; do run_one $r $SPATIAL_NSTEPS; done

echo "############ SPATIAL ANALYSIS ($FSUF, degree=1) ############"
python exact_cnv_analysis.py  --williamson $WTC --ref_levels $SPATIAL_REFS --nsteps $SPATIAL_NSTEPS \
    --tmax $TMAX --time_degree $TDEG --degree 1 --seed $SEED 2>&1 | tee lauter_spatial_${FSUF}.txt

if [ "$DO_TEMPORAL" = "1" ]; then
  echo "############ TEMPORAL sweep (pure): ref $TEMPORAL_REF, nsteps [$TEMPORAL_NSTEPS] ############"
  for ns in $TEMPORAL_NSTEPS; do run_one $TEMPORAL_REF $ns; done
  python exact_tcnv_analysis.py --williamson $WTC --ref_level $TEMPORAL_REF --timesteps $TEMPORAL_NSTEPS \
      --tmax $TMAX --time_degree $TDEG --degree 1 --seed $SEED 2>&1 | tee lauter_temporal_${FSUF}.txt
fi

echo "############ ALL DONE ($FSUF) ############"
echo "Results: lauter_spatial_${FSUF}.txt"
