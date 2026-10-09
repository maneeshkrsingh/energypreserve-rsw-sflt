"""Pure-vs-SFLT 2-panel comparison on a lon-lat map (matched colour scale).
  python make_compare_figs.py --pure <pure.pvd> --sflt <sflt.pvd> \
      --field {velocity,vorticity} --tsidx N --out fig.png --title "..."
Editable: colours/levels/labels below. Uses vtk python module (no ParaView).
"""
import os, argparse, xml.etree.ElementTree as ET
import numpy as np
import vtk
from vtk.util.numpy_support import vtk_to_numpy
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

p = argparse.ArgumentParser()
p.add_argument("--pure", required=True)
p.add_argument("--sflt", required=True)
p.add_argument("--field", choices=["velocity", "vorticity"], required=True)
p.add_argument("--tsidx", type=int, default=-1)
p.add_argument("--out", required=True)
p.add_argument("--title", default="")
p.add_argument("--projection", choices=["flat", "ortho"], default="flat")
p.add_argument("--center_lon", type=float, default=0.0)
p.add_argument("--center_lat", type=float, default=20.0)
p.add_argument("--vmax", type=float, default=None, help="force this colour-scale max (vorticity: +/-vmax; velocity: 0..vmax), for sharing a scale across figures")
p.add_argument("--r_sigma", type=float, default=None, help="measured r_sigma = ||u_noise||/||u|| for the SFLT panel label, e.g. 0.10")
args = p.parse_args()


def read(pvd, field, tsidx):
    root = ET.parse(pvd).getroot()
    entries = sorted((float(d.get("timestep")), d.get("file")) for d in root.iter("DataSet"))
    if tsidx < 0:
        tsidx = len(entries) - 1
    ts, pvtu = entries[max(0, min(tsidx, len(entries) - 1))]
    # A backed-up copy's .pvd (e.g. w6_rsw_output_SFLT_fig11.pvd) still
    # contains the literal "w6_rsw_output_SFLT/..." paths poisson_energy.py
    # always writes, pointing at the ORIGINAL (generic) output directory --
    # not the backup. The actual backed-up data lives in a folder named
    # after the pvd's own basename (cp -r <orig_dir> <pvd_basename>), either
    # nested (dst dir pre-existed: <basename>/<orig_dir_name>/...) or flat
    # (dst dir was new: <basename>/...) depending on cp's behaviour at backup
    # time. Try both before falling back to the generic cwd-relative path,
    # which may since have been overwritten by an unrelated later run of the
    # same testcase/suffix.
    backup_dir = os.path.splitext(pvd)[0]
    candidates = [os.path.join(backup_dir, pvtu), os.path.join(backup_dir, os.path.basename(pvtu))]
    for cand in candidates:
        if os.path.exists(cand):
            pvtu = cand
            break
    else:
        if not os.path.exists(pvtu):
            pvtu = os.path.join(os.path.dirname(pvd), os.path.basename(pvtu))
    r = vtk.vtkXMLPUnstructuredGridReader(); r.SetFileName(pvtu); r.Update()
    ug = r.GetOutput()
    pts = vtk_to_numpy(ug.GetPoints().GetData())
    lon = np.degrees(np.arctan2(pts[:, 1], pts[:, 0]))
    lat = np.degrees(np.arctan2(pts[:, 2], np.hypot(pts[:, 0], pts[:, 1])))
    pd = ug.GetPointData()
    if field == "velocity":
        # velocity = first sub-component of the mixed U=(u,G,D): the 3-comp "...[0]" array
        arr = next(pd.GetArray(i) for i in range(pd.GetNumberOfArrays())
                   if pd.GetArrayName(i).endswith("[0]") and pd.GetArray(i).GetNumberOfComponents() == 3)
        val = np.linalg.norm(vtk_to_numpy(arr), axis=1)
    else:
        val = vtk_to_numpy(pd.GetArray("vorticity"))
    return lon, lat, val, ts


lo1, la1, v1, ts = read(args.pure, args.field, args.tsidx)
lo2, la2, v2, _ = read(args.sflt, args.field, args.tsidx)

if args.field == "velocity":
    vmin, vmax = 0.0, args.vmax if args.vmax is not None else max(v1.max(), v2.max())
    cmap, lab = "viridis", r"$|u|$ (m s$^{-1}$)"
else:
    m = args.vmax if args.vmax is not None else max(abs(v1).max(), abs(v2).max())
    vmin, vmax = -m, m
    cmap, lab = "RdBu_r", r"vorticity (s$^{-1}$)"
levels = np.linspace(vmin, vmax, 41)

def to_ortho(lon_deg, lat_deg, clon_deg, clat_deg):
    lam, phi = np.radians(lon_deg), np.radians(lat_deg)
    lam0, phi0 = np.radians(clon_deg), np.radians(clat_deg)
    cosc = np.sin(phi0) * np.sin(phi) + np.cos(phi0) * np.cos(phi) * np.cos(lam - lam0)
    visible = cosc > 0
    x = np.cos(phi) * np.sin(lam - lam0)
    y = (np.cos(phi0) * np.sin(phi) - np.sin(phi0) * np.cos(phi) * np.cos(lam - lam0))
    return x, y, visible


plt.rcParams.update({"font.size": 14})
fig, axs = plt.subplots(1, 2, figsize=(13, 4), sharey=(args.projection == "flat"))
sflt_label = r"SFLT ($r_\sigma = %.2g$)" % args.r_sigma if args.r_sigma is not None else "SFLT"
for ax, (lo, la, v, sub) in zip(axs, [(lo1, la1, v1, "Deterministic"),
                                       (lo2, la2, v2, sflt_label)]):
    if args.projection == "ortho":
        x, y, vis = to_ortho(lo, la, args.center_lon, args.center_lat)
        tc = ax.tricontourf(x[vis], y[vis], v[vis], levels=levels, cmap=cmap, extend="both")
        ax.set_aspect("equal"); ax.axis("off")
        th = np.linspace(0, 2 * np.pi, 200)
        ax.plot(np.cos(th), np.sin(th), color="k", lw=0.8)
    else:
        tc = ax.tricontourf(lo, la, v, levels=levels, cmap=cmap, extend="both")
        ax.set_xlabel("longitude (deg)")
        ax.set_xlim(-180, 180); ax.set_ylim(-90, 90)
    ax.set_title(sub)
if args.projection == "flat":
    axs[0].set_ylabel("latitude (deg)")
fig.colorbar(tc, ax=axs, label=lab, shrink=0.85)
if args.title:
    fig.suptitle(args.title, y=1.02)
fig.savefig(args.out, dpi=150, bbox_inches="tight")
print(f"saved {args.out}  ({args.field}, t={ts/86400:.1f}d, range {vmin:.2e}..{vmax:.2e})")
