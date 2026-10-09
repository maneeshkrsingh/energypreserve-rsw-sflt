"""Render a field from a Firedrake .pvd onto a lon-lat map (matplotlib, editable).
  python render_field.py <pvd> <field> <tsidx> <out.png> [vmin vmax]
    field: 'velocity' (function_27 magnitude) or 'vorticity'
Uses the vtk python module (no ParaView/MPI). Colours/labels editable below.
"""
import sys, xml.etree.ElementTree as ET
import numpy as np
import vtk
from vtk.util.numpy_support import vtk_to_numpy
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

pvd, field, tsidx, out = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4]
vmin = float(sys.argv[5]) if len(sys.argv) > 5 else None
vmax = float(sys.argv[6]) if len(sys.argv) > 6 else None

# --- find the .pvtu for this timestep from the .pvd ---
root = ET.parse(pvd).getroot()
entries = sorted((float(ds.get("timestep")), ds.get("file")) for ds in root.iter("DataSet"))
ts, pvtu = entries[max(0, min(tsidx, len(entries) - 1))]
import os
pvtu = os.path.join(os.path.dirname(pvd), os.path.basename(pvtu)) if not os.path.exists(pvtu) else pvtu

r = vtk.vtkXMLPUnstructuredGridReader()
r.SetFileName(pvtu)
r.Update()
ug = r.GetOutput()

pts = vtk_to_numpy(ug.GetPoints().GetData())
x, y, z = pts[:, 0], pts[:, 1], pts[:, 2]
lon = np.degrees(np.arctan2(y, x))
lat = np.degrees(np.arctan2(z, np.hypot(x, y)))

pd = ug.GetPointData()
if field == "velocity":
    val = np.linalg.norm(vtk_to_numpy(pd.GetArray("function_27")), axis=1)
    cmap, label = "viridis", r"$|u|$ (m s$^{-1}$)"
else:
    val = vtk_to_numpy(pd.GetArray("vorticity"))
    cmap, label = "RdBu_r", r"vorticity (s$^{-1}$)"

plt.rcParams.update({"font.size": 13})
fig, ax = plt.subplots(figsize=(10, 5))
levels = np.linspace(vmin if vmin is not None else val.min(),
                     vmax if vmax is not None else val.max(), 41)
tc = ax.tricontourf(lon, lat, val, levels=levels, cmap=cmap, extend="both")
plt.colorbar(tc, ax=ax, label=label, shrink=0.85)
ax.set_xlabel("longitude (deg)"); ax.set_ylabel("latitude (deg)")
ax.set_xlim(-180, 180); ax.set_ylim(-90, 90)
ax.set_title(f"{out.replace('.png','')}  (t = {ts/86400:.1f} days)")
fig.tight_layout(); fig.savefig(out, dpi=150)
print(f"saved {out}  field={field}  range={val.min():.3e}..{val.max():.3e}")
