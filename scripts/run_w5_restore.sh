source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
echo "######## W5 15-DAY cPG RESTORE (regenerate w5_diagnostics_pure.csv) ########  $(date)"
mpiexec -n 16 python poisson_energy.py --williamson 5 --ref_level 5 --nsteps 9600 \
    --tmax 1296000 --diagnostics_every 10 --pure --no_output
echo "[restore] run done -- regenerating long-time figures $(date)"
python make_longtime_plots.py --csv w5_diagnostics_pure.csv --prefix w5 2>&1 | tail -3
echo "######## RESTORE DONE ########  $(date)"
