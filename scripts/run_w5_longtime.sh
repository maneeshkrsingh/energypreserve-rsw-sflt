[ -n "$FIREDRAKE_VENV" ] && source "$FIREDRAKE_VENV/bin/activate"   # your Firedrake venv, e.g. FIREDRAKE_VENV=~/firedrake
cd "${RSW_LIB:-$HOME/rsw_energy_conserving}"   # clone of colinjcotter/rsw_energy_conserving
echo "######## W5 15-DAY LONG-TIME ENERGY (Exp 1) ########  start $(date)"
mpiexec -n 16 python poisson_energy.py --williamson 5 --ref_level 5 --nsteps 9600 \
    --tmax 1296000 --diagnostics_every 10 --pure --no_output
echo "######## DONE ########  $(date)"
