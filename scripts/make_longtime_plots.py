"""Long-time diagnostics figures from a w{tc}_diagnostics_{suffix}.csv file.
Produces: <prefix>_energy_longtime.png, <prefix>_div_longtime.png, <prefix>_casimirs.png
Columns expected: step,t_days,H,rel_energy_err,mass,total_vorticity,pot_enstrophy,div_L2
"""
import csv, argparse
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

p = argparse.ArgumentParser()
p.add_argument("--csv", default="w5_diagnostics_pure.csv")
p.add_argument("--prefix", default="w5")
p.add_argument("--title", default="")
args = p.parse_args()

rows = list(csv.DictReader(open(args.csv)))
col = lambda k: np.array([float(r[k]) for r in rows])
t   = col("t_days")
ee  = np.abs(col("rel_energy_err"))
mass, pe, tv, dv = col("mass"), col("pot_enstrophy"), col("total_vorticity"), col("div_L2")

plt.rcParams.update({"font.size": 14})

# ---- 1. energy conservation (log-y) ----
fig, ax = plt.subplots(figsize=(6.5, 4))
ax.semilogy(t, ee, "b-", lw=2)
ax.set_xlabel("Time (days)"); ax.set_ylabel(r"$|(H-H_0)/H_0|$")
if args.title:
    ax.set_title(args.title)
ax.grid(True, which="both", alpha=0.3)
fig.tight_layout(); fig.savefig(f"{args.prefix}_energy_longtime.png", dpi=150, bbox_inches="tight")
print(f"energy: max |rel err| = {ee.max():.3e}  final = {ee[-1]:.3e}")

# ---- 2. divergence (linear-y; bounded oscillation) ----
fig, ax = plt.subplots(figsize=(6.5, 4))
ax.plot(t, dv, "g-", lw=1.5)
ax.set_xlabel("Time (days)"); ax.set_ylabel(r"$\|\nabla\cdot u\|_{L^2}$")
if args.title:
    ax.set_title(args.title)
ax.grid(True, alpha=0.3)
fig.tight_layout(); fig.savefig(f"{args.prefix}_div_longtime.png", dpi=150, bbox_inches="tight")
print(f"div_L2: {dv.min():.2f} .. {dv.max():.2f}")

# ---- 3. Casimirs (log-y relative drift) ----
# Enstrophy & total vorticity vary above data precision -> plot as curves.
# Mass is conserved BELOW the CSV precision (only ~2 distinct stored values), so its
# relative drift is a quantised 0/round-off step that looks broken on a log axis;
# we therefore show it as a single round-off BOUND line, not a (meaningless) curve.
Omega, R0 = 7.292e-5, 6371220.0
Z0 = 2.0 * Omega * 4.0 * np.pi * R0**2
floor = 1e-17
dM = np.abs((mass - mass[0]) / mass[0])
dZ = np.maximum(np.abs((pe - pe[0]) / pe[0]), floor)
dV = np.maximum(np.abs(tv / Z0), floor)
mass_bound = max(dM.max(), floor)
fig, ax = plt.subplots(figsize=(6.5, 4))
ax.semilogy(t, dZ, "r-",  lw=2, label="potential enstrophy")
ax.semilogy(t, dV, "b-",  lw=2, label=r"total vorticity  ($/\,2\Omega A$)")
# mass bound: horizontal line spanning only the data range (not the axhline full width)
ax.plot([t[0], t[-1]], [mass_bound, mass_bound], "k--", lw=1.5,
        label=rf"mass (conserved, $\leq{mass_bound:.0e}$)")
ax.set_xlim(0, t[-1])
ax.set_xlabel("Time (days)"); ax.set_ylabel(r"relative drift  $|\Delta C/C_0|$")
if args.title:
    ax.set_title(args.title)
ax.grid(True, which="both", alpha=0.3); ax.legend(fontsize=11, loc="best")
fig.tight_layout(); fig.savefig(f"{args.prefix}_casimirs.png", dpi=150, bbox_inches="tight")
print(f"mass rel drift  = {abs(mass[-1]-mass[0])/abs(mass[0]):.3e}")
print(f"enstrophy drift = {(pe[-1]-pe[0])/pe[0]:+.3e}")
print(f"|tv|/Z0 range   = {np.abs(tv/Z0).min():.2e} .. {np.abs(tv/Z0).max():.2e}")
