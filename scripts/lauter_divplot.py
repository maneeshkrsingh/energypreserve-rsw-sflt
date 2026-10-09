import numpy as np, argparse
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# div(u) L2 norm per timestep. Defaults to the last Lauter run; override for other cases.
p = argparse.ArgumentParser()
p.add_argument("--infile", default="rsw_div_norms_pure.txt")
p.add_argument("--tmax", type=float, default=43200.0)
p.add_argument("--title", default="")
p.add_argument("--out", default="lauter_div_norms.png")
p.add_argument("--smooth", type=int, default=0, help="moving-average window in steps; 0 = off")
p.add_argument("--hide_raw", action='store_true', help="omit the raw trace, show only the smoothed curve")
p.add_argument("--color", default="b", help="matplotlib line colour")
p.add_argument("--days", action='store_true', help="x-axis in days instead of hours")
p.add_argument("--label", default=None, help="legend label, e.g. 'SFLT (seed 1)'")
args = p.parse_args()

div = np.loadtxt(args.infile)
nsteps = len(div)
tmax = args.tmax
dt = tmax / nsteps
t_hours = np.arange(1, nsteps + 1) * dt / 3600.0
t = t_hours / 24.0 if args.days else t_hours

plt.rcParams.update({'font.size': 14})
fig, ax = plt.subplots(figsize=(6.5, 4))
if args.smooth > 1:
    from scipy.ndimage import uniform_filter1d
    div_s = uniform_filter1d(div, size=args.smooth, mode='nearest')
    if not args.hide_raw:
        ax.plot(t, div, args.color + '-', linewidth=1, alpha=0.30, label='raw')
    ax.plot(t, div_s, args.color + '-', linewidth=2.5,
            label=f'{args.smooth}-step moving average')
    ax.legend()
else:
    ax.plot(t, div, args.color + '-', linewidth=2, label=args.label)
    if args.label:
        ax.legend()
ax.set_xlabel('Time (days)' if args.days else 'Time (hours)')
ax.set_ylabel(r'$\|\nabla\cdot u\|_{L^2}$')
if args.title:
    ax.set_title(args.title)
ax.grid(True, alpha=0.3)
fig.tight_layout()
fig.savefig(args.out, dpi=150, bbox_inches="tight")

print(f"points={nsteps}  dt={dt:.2f}s")
print(f"min={div.min():.4e}  max={div.max():.4e}  mean={div.mean():.4e}  final={div[-1]:.4e}")
