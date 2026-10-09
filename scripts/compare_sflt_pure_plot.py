import numpy as np, argparse
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

# Overlay SFLT vs pure (deterministic) traces for energy error or div norm.
p = argparse.ArgumentParser()
p.add_argument("--sflt", required=True)
p.add_argument("--pure", required=True)
p.add_argument("--tmax", type=float, required=True)
p.add_argument("--quantity", choices=["energy", "div"], required=True)
p.add_argument("--smooth", type=int, default=0, help="moving-average window in steps for div; 0 = off")
p.add_argument("--title", default="")
p.add_argument("--out", required=True)
args = p.parse_args()

sflt = np.loadtxt(args.sflt)
pure = np.loadtxt(args.pure)

dt = args.tmax / len(sflt)
t_sflt = np.arange(1, len(sflt) + 1) * dt / 3600.0
t_pure = np.arange(1, len(pure) + 1) * dt / 3600.0

plt.rcParams.update({'font.size': 14})
fig, ax = plt.subplots(figsize=(6.5, 4))

if args.quantity == "energy":
    ax.semilogy(t_sflt, np.abs(sflt), 'r-', linewidth=2, label='SFLT')
    ax.semilogy(t_pure, np.abs(pure), 'k--', linewidth=2, label='pure (deterministic)')
    ax.set_ylabel('Relative Energy error')
else:
    if args.smooth > 1:
        from scipy.ndimage import uniform_filter1d
        sflt_s = uniform_filter1d(sflt, size=args.smooth, mode='nearest')
        pure_s = uniform_filter1d(pure, size=args.smooth, mode='nearest')
        ax.plot(t_sflt, sflt, 'r-', linewidth=1, alpha=0.25)
        ax.plot(t_pure, pure, 'k-', linewidth=1, alpha=0.25)
        ax.plot(t_sflt, sflt_s, 'r-', linewidth=2.5, label='SFLT (smoothed)')
        ax.plot(t_pure, pure_s, 'k--', linewidth=2.5, label='pure (smoothed)')
    else:
        ax.plot(t_sflt, sflt, 'r-', linewidth=2, label='SFLT')
        ax.plot(t_pure, pure, 'k--', linewidth=2, label='pure (deterministic)')
    ax.set_ylabel(r'$\|\nabla\cdot u\|_{L^2}$')

ax.set_xlabel('Time (hours)')
if args.title:
    ax.set_title(args.title)
ax.legend()
ax.grid(True, which='both', alpha=0.3)
fig.tight_layout()
fig.savefig(args.out, dpi=150, bbox_inches="tight")
print(f"saved {args.out}  (SFLT: {len(sflt)} pts, pure: {len(pure)} pts)")
