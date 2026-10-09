#!/bin/bash
# Temporal convergence via NUMERICAL fine-dt reference (no spatial floor), Lauter Ex.3
# --pure, fixed mesh ref4 coords_degree=2, cPG P1. Error = ||u(dt) - u(dt_ref)|| on the
# SAME mesh, so spatial error cancels and the rate stays ~2 over the whole ladder.
# ns=1024 is the fine reference. Courant = u0*dt/h = 3.735/nsteps at ref4 (all < 0.9).
source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
mkdir -p logs
REF=4; TMAX=43200; TDEG=1; SEED=987654321
NSTEPS="8 16 32 64 128 256 1024"

for ns in $NSTEPS; do
  echo "=== ref$REF nsteps $ns : start $(date +%H:%M:%S) ==="
  mpiexec -n 8 python poisson_energy.py --williamson 2 --pure \
      --ref_level $REF --nsteps $ns --tmax $TMAX --time_degree $TDEG --seed $SEED \
      --no_output > logs/tcnv_numref_ref${REF}_ns${ns}.log 2>&1 \
    && echo "[done] ns $ns $(date +%H:%M:%S)" || echo "[FAIL] ns $ns (see log)"
done

echo "=== ANALYSIS (vs fine-dt numerical reference ns=1024) ==="
python tcnv_analysis.py --williamson 2 --ref_level $REF --seeds $SEED \
    --timesteps $NSTEPS --tmax $TMAX --time_degree $TDEG 2>&1 | tee lauter_temporal_numref_ref4.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
