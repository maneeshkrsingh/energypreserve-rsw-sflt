"""Single-seed W5 SFLT energy + divergence plots.
Reads the per-step text dumps written by poisson_energy.py for the ref5,
5-day, dt=135 s SFLT run (run_w5_sflt.sh, seed 1).

  python make_w5_sflt_energy_plot.py
"""
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

nsteps = 3200
tmax = 432000.0  # 5 days in seconds
dt = tmax / nsteps
t_days = (np.arange(nsteps) + 1) * dt / 86400.0

energy = np.abs(np.loadtxt("w5_energy_errors_SFLT.txt"))
div = np.loadtxt("w5_div_norms_SFLT.txt")

plt.rcParams.update({"font.size": 14})

fig, ax = plt.subplots(figsize=(6.5, 4))
ax.semilogy(t_days, energy, "C3-", lw=2, label="SFLT (seed 1)")
ax.set_xlabel("Time (days)")
ax.set_ylabel(r"$|(H-H_0)/H_0|$")
ax.grid(True, which="both", alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig("w5_sflt_energy.png", dpi=150, bbox_inches="tight")
print("saved w5_sflt_energy.png")

fig, ax = plt.subplots(figsize=(6.5, 4))
ax.plot(t_days, div, "C3-", lw=2, label="SFLT (seed 1)")
ax.set_xlabel("Time (days)")
ax.set_ylabel(r"$\|\nabla\cdot u\|_{L^2}$")
ax.grid(True, alpha=0.3)
ax.legend()
fig.tight_layout()
fig.savefig("w5_sflt_div.png", dpi=150, bbox_inches="tight")
print("saved w5_sflt_div.png")
