SCRIPTS_DIR="$(cd "$(dirname "$0")" && pwd)"   # this folder (plot scripts)
[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
# 1. wait for Exp 4 ensemble to finish (frees cores)
while tmux has-session -t w6exp34 2>/dev/null; do sleep 30; done
echo "[finish] exp34 done $(date) -- building ensemble figure"
python "$SCRIPTS_DIR/make_sflt_energy_plots.py" --mode ensemble --prefix w6 2>&1 | tail -1
# 2. clear stale W5 VTK (old May/Jun runs, 2.4 GB)
rm -rf w5_rsw_output_pure w5_rsw_output_pure.pvd w5_rsw_output_SFLT w5_rsw_output_SFLT.pvd
echo "[finish] stale W5 dirs cleared -- starting deterministic W5 viz $(date)"
# 3. deterministic W5 viz: ref5, 5 days, dt=135s, 6 snapshots (t=0..5 days)
mpiexec -n 16 python poisson_energy.py --williamson 5 --ref_level 5 --nsteps 3200 \
    --tmax 432000 --ndumps 640 --pure > logs/w5_viz_det.log 2>&1
echo "[finish] W5 viz DONE $(date)  -> w5_rsw_output_pure.pvd ($(grep -coE 'timestep=' w5_rsw_output_pure.pvd) snapshots)"
