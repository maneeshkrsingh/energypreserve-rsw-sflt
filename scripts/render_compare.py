# pvbatch render_compare.py <pvd> <field> <tsidx> <out.png> <vmin> <vmax>
#   field: "velocity" (uses function_27 magnitude) or "vorticity"
# Renders the sphere coloured by the field at timestep tsidx with a FIXED [vmin,vmax]
# range (so pure and SFLT panels are directly comparable). Same camera every time.
from paraview.simple import *
import sys

pvd, field, tsidx, out, vmin, vmax = sys.argv[1], sys.argv[2], int(sys.argv[3]), sys.argv[4], float(sys.argv[5]), float(sys.argv[6])

reader = PVDReader(FileName=pvd)
reader.UpdatePipeline()
view = GetActiveViewOrCreate('RenderView')
view.ViewSize = [900, 900]
view.Background = [1, 1, 1]
view.OrientationAxesVisibility = 0

disp = Show(reader, view)
disp.Representation = 'Surface'

# set time
tvals = reader.TimestepValues
if tvals:
    tsidx = max(0, min(tsidx, len(tvals) - 1))
    view.ViewTime = tvals[tsidx]
    GetTimeKeeper().Time = tvals[tsidx]
reader.UpdatePipeline(view.ViewTime)

if field == 'velocity':
    ColorBy(disp, ('POINTS', 'function_27', 'Magnitude'))
    lut = GetColorTransferFunction('function_27')
else:
    ColorBy(disp, ('POINTS', field))
    lut = GetColorTransferFunction(field)

lut.RescaleTransferFunction(vmin, vmax)
if field != 'velocity':
    lut.ApplyPreset('Cool to Warm', True)   # diverging for vorticity
disp.SetScalarBarVisibility(view, True)
GetScalarBar(lut, view).Title = field
GetScalarBar(lut, view).ComponentTitle = ''

ResetCamera(view)
view.CameraPosition = [x * 2.4 for x in view.CameraFocalPoint] \
    if any(view.CameraFocalPoint) else [0, 0, 1.7e7]
# fixed oblique view of the sphere
view.CameraPosition = [1.2e7, -1.4e7, 1.0e7]
view.CameraFocalPoint = [0, 0, 0]
view.CameraViewUp = [0, 0, 1]
Render(view)
SaveScreenshot(out, view, ImageResolution=[900, 900])
print("saved", out)
