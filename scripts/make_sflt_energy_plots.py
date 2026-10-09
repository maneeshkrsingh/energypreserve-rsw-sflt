"""SFLT energy-conservation figures (Exp 3 amplitude sweep, Exp 4 ensemble).
Reads the per-run diagnostics CSVs (columns include t_days, rel_energy_err).

  python make_sflt_energy_plots.py --mode amp       --prefix w6
  python make_sflt_energy_plots.py --mode ensemble  --prefix w6

Edit labels/title/colour via the args or the small dicts below.
"""
import csv, glob, os, argparse
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

p = argparse.ArgumentParser()
p.add_argument("--mode", choices=["amp", "ensemble"], required=True)
p.add_argument("--prefix", default="w6")
p.add_argument("--out", default=None)
p.add_argument("--title", default="")
p.add_argument("--labels", default=None, help="comma-separated legend labels, replacing the nominal amp_01/10/25/50 defaults")
args = p.parse_args()


def load(csvf):
    r = list(csv.DictReader(open(csvf)))
    t = np.array([float(x["t_days"]) for x in r])
    e = np.abs(np.array([float(x["rel_energy_err"]) for x in r]))
    return t, e


plt.rcParams.update({"font.size": 14})
fig, ax = plt.subplots(figsize=(6.5, 4))

if args.mode == "amp":
    # (file tag, legend label, colour) — edit freely
    labs = args.labels.split(",") if args.labels else ["deterministic", "1%", "10%", "25%", "50%"]
    series = [("amp_pure", labs[0], "k"),
              ("amp_01", labs[1], "C0"),
              ("amp_10", labs[2], "C1"),
              ("amp_25", labs[3], "C2"),
              ("amp_50", labs[4], "C3")]
    for tag, lab, c in series:
        f = f"{args.prefix}_diag_{tag}.csv"
        if not os.path.exists(f):
            continue
        t, e = load(f)
        ax.semilogy(t, e, color=c, lw=2, label=lab)
    ax.legend(title=r"$r_\sigma$")
    out = args.out or f"{args.prefix}_sflt_amp_sweep.png"
    if args.title:
        ax.set_title(args.title)
else:
    fs = sorted(glob.glob(f"{args.prefix}_diag_ens_seed*.csv"),
                key=lambda s: int(s.split("seed")[-1].split(".")[0]))
    # seeds were run with different diagnostics_every settings at different
    # times, so their t_days grids don't all match in length; interpolate
    # each onto the finest (densest) grid found so they can be stacked.
    raw = [load(f) for f in fs]
    T = max((t for t, _ in raw), key=len)
    E = np.array([np.interp(T, t, e) for t, e in raw])
    ax.fill_between(T, E.min(0), E.max(0), alpha=0.3, color="C0",
                    label=f"min–max ({len(fs)} seeds)")
    ax.semilogy(T, E.mean(0), "C0-", lw=2, label="mean")
    ax.set_yscale("log")
    ax.legend()
    out = args.out or f"{args.prefix}_sflt_ensemble_energy.png"
    if args.title:
        ax.set_title(args.title)

ax.set_xlabel("Time (days)")
ax.set_ylabel(r"$|(H-H_0)/H_0|$")
ax.grid(True, which="both", alpha=0.3)
fig.tight_layout()
fig.savefig(out, dpi=150, bbox_inches="tight")
print("saved", out)
