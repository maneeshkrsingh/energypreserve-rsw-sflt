source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
echo "=== PURE W6 (ref5, 2 days, 6 dumps) ==="
mpiexec -n 16 python poisson_energy.py --williamson 6 --ref_level 5 --nsteps 400 \
    --tmax 172800 --ndumps 80 --pure > logs/w6_compare_pure.log 2>&1
echo "=== SFLT W6 (ref5, 2 days, 6 dumps, lam=1e6 ~10% noise) ==="
mpiexec -n 16 python poisson_energy.py --williamson 6 --ref_level 5 --nsteps 400 \
    --tmax 172800 --ndumps 80 --lam 1e6 --seed 1 > logs/w6_compare_sflt.log 2>&1
echo "=== DONE ==="
