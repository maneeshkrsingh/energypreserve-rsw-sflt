[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
echo "=== SFLT W6 STRONG (~50% noise, noise_scale=2e8, ref5, 2 days, 6 dumps) ==="
mpiexec -n 16 python poisson_energy.py --williamson 6 --ref_level 5 --nsteps 400 \
    --tmax 172800 --ndumps 80 --lam 1e6 --seed 1 > logs/w6_strong_viz.log 2>&1
echo "=== DONE ==="
