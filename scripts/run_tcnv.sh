#!/bin/bash
# Temporal convergence: multiple realizations on fixed mesh.
# Usage: bash run_tcnv.sh [N_SEEDS] [TIME_DEGREE] [MODE]
#   MODE = sflt (default) or pure
#   Pure is deterministic so N_SEEDS is forced to 1.

[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
mkdir -p logs

N_SEEDS=${1:-2}
TIME_DEGREE=${2:-1}
MODE=${3:-sflt}
REF=${REF:-4}
WTC=${WTC:-6}
TMAX=${TMAX:-172800}   # W6: 2 days. W5: override e.g. TMAX=432000 (5 days)
NP=16
LAM=${LAM:-1e6}       # physical noise (small-scale): stochastic O(dt^0.5) term dominates -> exposes strong order
NOISE_SCALE=${NOISE_SCALE:-3.8e7}   # ~10-20% for W6; W5 (slower) needs smaller
TAG="w${WTC}"

if [ "$MODE" = "pure" ]; then
    N_SEEDS=1
    if [ "$TIME_DEGREE" = "1" ]; then
        NSTEPS_FINE=3200
        NSTEPS_LIST="1600 800 400 200"
    else
        NSTEPS_FINE=1600
        NSTEPS_LIST="800 400 200 100"
    fi
else
    # ns6400 reference is >=4x finer than every test point (200..1600) so none
    # are contaminated by reference proximity -> all rates are valid.
    NSTEPS_FINE=6400
    NSTEPS_LIST="1600 800 400 200"
fi

echo "Mode: $MODE  time_degree: $TIME_DEGREE  seeds: $N_SEEDS"
echo "nsteps: $NSTEPS_FINE (finest)  coarser: $NSTEPS_LIST"

for seed in $(seq 1 $N_SEEDS); do
    echo ""
    echo "=== Seed ${seed} / ${N_SEEDS} ==="

    if [ "$MODE" = "pure" ]; then
        # Pure: deterministic, no noise sharing needed
        for nsteps in $NSTEPS_FINE $NSTEPS_LIST; do
            mpiexec -n $NP python poisson_energy.py --williamson $WTC --ref_level $REF --nsteps $nsteps \
                --tmax $TMAX --seed 1 --time_degree $TIME_DEGREE --pure --no_output \
                > logs/${TAG}_pure_tcnv_ns${nsteps}.log 2>&1 && echo "[done] pure ns$nsteps" || echo "[FAIL] pure ns$nsteps"
        done
    else
        NOISE_DIR="./noise_checkpoints/seed${seed}"
        # Finest dt: generate dW and save (shared Brownian path)
        mpiexec -n $NP python poisson_energy.py --williamson $WTC --ref_level $REF --nsteps $NSTEPS_FINE --seed $seed \
            --tmax $TMAX --lam $LAM --noise_scale $NOISE_SCALE --time_degree $TIME_DEGREE --save_noise --noise_dir $NOISE_DIR --no_output \
            > logs/${TAG}_sflt_tcnv_ns${NSTEPS_FINE}_seed${seed}.log 2>&1 && echo "[done] ns$NSTEPS_FINE seed$seed" || echo "[FAIL] ns$NSTEPS_FINE seed$seed"
        # Coarser dt: load and sum fine dW
        for nsteps in $NSTEPS_LIST; do
            coarsening=$((NSTEPS_FINE / nsteps))
            mpiexec -n $NP python poisson_energy.py --williamson $WTC --ref_level $REF --nsteps $nsteps --seed $seed \
                --tmax $TMAX --lam $LAM --noise_scale $NOISE_SCALE --time_degree $TIME_DEGREE --load_noise --coarsening $coarsening \
                --noise_dir $NOISE_DIR --no_output \
                > logs/${TAG}_sflt_tcnv_ns${nsteps}_seed${seed}.log 2>&1 && echo "[done] ns$nsteps seed$seed" || echo "[FAIL] ns$nsteps seed$seed"
        done
    fi
done

echo ""
TS=$(echo "$NSTEPS_LIST $NSTEPS_FINE" | tr ' ' '\n' | sort -n | tr '\n' ' ')
echo "=== ANALYSIS (tcnv, $MODE; reference = finest dt, nsteps=$NSTEPS_FINE) ==="
if [ "$MODE" = "pure" ]; then
    python tcnv_analysis.py --williamson $WTC --seeds 1 --time_degree $TIME_DEGREE --timesteps $TS \
        2>&1 | tee ${TAG}_pure_temporal.txt
else
    python tcnv_analysis.py --SFLT --williamson $WTC --seeds $(seq -s ' ' 1 $N_SEEDS) \
        --time_degree $TIME_DEGREE --timesteps $TS 2>&1 | tee ${TAG}_sflt_temporal.txt
fi
