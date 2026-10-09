#!/bin/bash
# Spatial convergence: multiple realizations, varying mesh, fixed dt.
# Usage: bash run_scnv.sh [N_SEEDS]
# Finest mesh (ref 5) saves dU_3; coarser meshes load via cross-mesh interpolation.

[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs

N_SEEDS=${1:-5}
NSTEPS=${NSTEPS:-400}
REF_FINE=5
REF_LIST="4 3 2"
WTC=${WTC:-6}
TMAX=${TMAX:-172800}   # W6: 2 days (RH wave smooth). W5: override e.g. TMAX=432000 (5 days)
NP=16
LAM=${LAM:-6e6}       # large correlation length: noise resolved on ALL meshes (lambda/h>3 at ref2)
NOISE_SCALE=${NOISE_SCALE:-3.8e7}   # ~10% for W6 (U~50); W5 (U~20) needs smaller, e.g. 1.5e7
TAG="w${WTC}"

for seed in $(seq 1 $N_SEEDS); do
    echo ""
    echo "=== Seed ${seed} / ${N_SEEDS} ==="

    # Finest mesh first: generates and saves noise reference
    mpiexec -n $NP python poisson_energy.py --williamson $WTC --ref_level $REF_FINE --ref_level_fine $REF_FINE \
        --nsteps $NSTEPS --tmax $TMAX --lam $LAM --noise_scale $NOISE_SCALE --seed $seed --no_output \
        > logs/${TAG}_sflt_scnv_ref${REF_FINE}_seed${seed}.log 2>&1 && echo "[done] ref$REF_FINE seed$seed" || echo "[FAIL] ref$REF_FINE seed$seed"

    # Coarser meshes: load noise from finest via cross-mesh interpolation
    for ref in $REF_LIST; do
        mpiexec -n $NP python poisson_energy.py --williamson $WTC --ref_level $ref --ref_level_fine $REF_FINE \
            --nsteps $NSTEPS --tmax $TMAX --lam $LAM --noise_scale $NOISE_SCALE --seed $seed --no_output \
            > logs/${TAG}_sflt_scnv_ref${ref}_seed${seed}.log 2>&1 && echo "[done] ref$ref seed$seed" || echo "[FAIL] ref$ref seed$seed"
    done
done

echo ""
echo "=== ANALYSIS (scnv, SFLT, averaged over seeds; reference = ref$REF_FINE) ==="
python scnv_analysis.py --SFLT --williamson $WTC --ref_levels 2 3 4 $REF_FINE --nsteps $NSTEPS \
    --time_degree 1 --seeds $(seq -s ' ' 1 $N_SEEDS) 2>&1 | tee ${TAG}_sflt_spatial.txt
echo "Done. Result: ${TAG}_sflt_spatial.txt"
