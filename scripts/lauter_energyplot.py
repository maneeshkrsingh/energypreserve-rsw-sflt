import numpy as np, argparse
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# relative energy drift |(E-E0)/E0| per timestep. Defaults to Lauter; override for others.
p = argparse.ArgumentParser()
p.add_argument("--infile", default="rsw_energy_errors_pure.txt")
p.add_argument("--tmax", type=float, default=43200.0)
p.add_argument("--title", default="")
p.add_argument("--out", default="lauter_energy_errors.png")
p.add_argument("--smooth", type=int, default=0, help="centred moving-average window (steps); 0 = off")
p.add_argument("--color", default="g", help="matplotlib line colour")
p.add_argument("--days", action='store_true', help="x-axis in days instead of hours")
p.add_argument("--label", default=None, help="legend label, e.g. 'SFLT (seed 1)'")
args = p.parse_args()

e = np.loadtxt(args.infile)
nsteps = len(e)
tmax = args.tmax
dt = tmax / nsteps
t_hours = np.arange(1, nsteps + 1) * dt / 3600.0
t = t_hours / 24.0 if args.days else t_hours

ae = np.abs(e)
if args.smooth > 0:                       # light smoothing; leave the ends raw
    w = args.smooth; half = w // 2
    ae_s = np.convolve(ae, np.ones(w) / w, mode="same")
    ae_s[:half] = ae[:half]; ae_s[-half:] = ae[-half:]
    ae = ae_s

plt.rcParams.update({'font.size': 14})
fig, ax = plt.subplots(figsize=(6.5, 4))
ax.semilogy(t, ae, args.color + '-', linewidth=2, label=args.label)
ax.set_xlabel('Time (days)' if args.days else 'Time (hours)')
ax.set_ylabel(r'$|(H-H_0)/H_0|$')
if args.label:
    ax.legend()
if args.title:
    ax.set_title(args.title)
ax.grid(True, which='both', alpha=0.3)
fig.tight_layout()
fig.savefig(args.out, dpi=150, bbox_inches="tight")

print(f"points={nsteps}  dt={dt:.2f}s")
print(f"|err| min={np.abs(e).min():.4e}  max={np.abs(e).max():.4e}  final={abs(e[-1]):.4e}")
