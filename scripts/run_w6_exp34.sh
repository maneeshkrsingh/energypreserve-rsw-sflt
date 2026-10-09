source ~/march26_firedrke/venv-firedrake/bin/activate
cd ~/rsw_energy_conserving
mkdir -p logs
NS_1=1.28e8; NS_10=1.28e9; NS_25=3.21e9; NS_50=6.41e9
COMMON="--williamson 6 --ref_level 5 --nsteps 400 --tmax 172800 --lam 6e6 --diagnostics_every 10 --no_output"

echo "######## EXP 3: SFLT amplitude sweep ########  $(date)"
# deterministic baseline
mpiexec -n 16 python poisson_energy.py $COMMON --pure > logs/w6_amp_pure.log 2>&1
cp w6_diagnostics_pure.csv w6_diag_amp_pure.csv && echo "[amp det] done"
for pct in 01 10 25 50; do
  case $pct in 01) ns=$NS_1;; 10) ns=$NS_10;; 25) ns=$NS_25;; 50) ns=$NS_50;; esac
  mpiexec -n 16 python poisson_energy.py $COMMON --noise_scale $ns --seed 1 > logs/w6_amp_${pct}.log 2>&1
  cp w6_diagnostics_SFLT.csv w6_diag_amp_${pct}.csv
  echo "[amp ${pct}%] done  ratio=$(grep 'u_noise/u ratio' logs/w6_amp_${pct}.log | head -1 | grep -oE '[0-9.]+ ' | head -1)"
done

echo "######## EXP 4: SFLT ensemble (16 seeds @ ~10%) ########  $(date)"
for s in $(seq 1 16); do
  mpiexec -n 16 python poisson_energy.py $COMMON --noise_scale $NS_10 --seed $s > logs/w6_ens_seed${s}.log 2>&1
  cp w6_diagnostics_SFLT.csv w6_diag_ens_seed${s}.csv && echo "[ensemble seed $s] done"
done
echo "######## EXP 3+4 DONE ########  $(date)"
