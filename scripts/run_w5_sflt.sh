source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
# wait for the deterministic W5 viz (w5finish) to finish, then run strong-noise SFLT
while tmux has-session -t w5finish 2>/dev/null; do sleep 30; done
echo "[w5sflt] pure viz done $(date) -- starting W5 SFLT (~50% noise)"
mpiexec -n 16 python poisson_energy.py --williamson 5 --ref_level 5 --nsteps 3200 \
    --tmax 432000 --ndumps 640 --lam 1e6 --noise_scale 6e7 --seed 1 > logs/w5_viz_sflt50.log 2>&1
echo "[w5sflt] DONE $(date) -> w5_rsw_output_SFLT.pvd ($(grep -coE 'timestep=' w5_rsw_output_SFLT.pvd) snapshots)"
