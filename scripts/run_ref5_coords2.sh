#!/bin/bash
# coords_degree=2 (set in sw_tools.py) Läuter Ex.3 spatial sweep: add ref 5, then
# analyse refs 2-5 as a consistent coords2 set. refs 2-4 already on disk from prior run.
source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
mkdir -p logs
CHK=../RSW_checkpoint/new_RSW_checkpoint

# back up the stale coords1 ref5 checkpoint before overwriting
cp -f "$CHK/velocity_timestepping_w2_5_2000_pure_tdeg1_seed987654321.h5" \
      "$CHK/backup_coords1_w2_5_2000.h5" 2>/dev/null && echo "[backup] coords1 ref5"

echo "=== coords2 ref 5 : start $(date +%H:%M:%S) ==="
mpiexec -n 8 python poisson_energy.py --williamson 2 --pure \
    --ref_level 5 --nsteps 2000 --tmax 43200 --time_degree 1 --seed 987654321 \
    --no_output > logs/coords2_ref5_ns2000.log 2>&1 \
  && echo "[done] coords2 ref 5 $(date +%H:%M:%S)" || echo "[FAIL] coords2 ref 5 (see log)"

echo "=== ANALYSIS refs 2 3 4 5 ==="
python exact_cnv_analysis.py --williamson 2 --ref_levels 2 3 4 5 --nsteps 2000 \
    --tmax 43200 --time_degree 1 --seed 987654321 2>&1 | tee lauter_spatial_coords2_full.txt
echo "=== ALL DONE $(date +%H:%M:%S) ==="
