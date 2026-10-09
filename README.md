# Energy-conserving stochastic RSW: numerical results

Scripts, raw numbers and figures for the numerical experiments of the paper on
the energy-conserving stochastic rotating shallow water equations (SFLT noise).
The simulation code is a separate library:

- https://github.com/colinjcotter/rsw_energy_conserving (`main` at commit
  `ed92c7f` when this repository was created; the convergence analysis scripts
  `scnv_analysis.py`, `tcnv_analysis.py`, `exact_cnv_analysis.py` and
  `exact_tcnv_analysis.py` live there).

This repository keeps the numbers behind every graph and table, so the figures
can be regenerated without re-running the simulations.

## Layout

- `data/` — the numbers behind the graphs and tables (about 2.4 MB)
  - `w5_*`, `w6_*`, `rsw_*` — per-step energy error and divergence norm
    (`*_energy_errors_*.txt`, `*_div_norms_*.txt`; one value per line) and
    long-time diagnostics (`*_diag*.csv`: step, t_days, H, rel_energy_err, mass,
    total_vorticity, pot_enstrophy, div_L2). `w5` = Williamson 5, `w6` =
    Williamson 6, `rsw` = Läuter Example 3.
  - `w6_sflt_spatial.txt`, `w6_sflt_temporal.txt`, `w6_*_pure.txt` — Williamson 6
    convergence tables (analysis output)
  - `lauter_spatial_*.txt`, `lauter_temporal_*.txt` — error against the exact
    Läuter Example 3 solution
  - `table*_results*`, `results_summary.csv` — further summary numbers
- `figures/` — the figures (`.png`) and LaTeX tables / figure wrappers (`.tex`).
  A name containing `figNN` (e.g. `w6_fig11_vorticity_strong_forcing.png`) is
  the paper's Fig. NN; the rest are earlier or supporting versions.
- `scripts/` — plotting scripts, the shell scripts that ran the simulations, and
  `make_panels.sh` for the comparison panels

## Regenerating the figures

The plot scripts read files in the current directory, so run them from `data/`.

    cd data

Energy error and divergence norm (Läuter, 12 h):

    python ../scripts/lauter_energyplot.py --infile rsw_energy_errors_pure.txt --tmax 43200 --title "Läuter Ex.3" --out ../figures/lauter_energy_errors.png
    python ../scripts/lauter_divplot.py --infile rsw_div_norms_pure.txt --tmax 43200 --title "Läuter Ex.3" --out ../figures/lauter_div_norms.png

Williamson 6, deterministic (2 days, `--tmax 172800`):

    python ../scripts/lauter_energyplot.py --infile w6_energy_errors_pure.txt --tmax 172800 --title "Williamson 6" --out ../figures/w6_energy_errors.png
    python ../scripts/lauter_divplot.py --infile w6_div_norms_pure.txt --tmax 172800 --title "Williamson 6" --out ../figures/w6_div_norms.png

Williamson 6 with SFLT (ref 5, 2 days). `--smooth` is a moving-average window:

    python ../scripts/lauter_energyplot.py --infile w6_energy_errors_SFLT_ref5.txt --tmax 172800 --smooth 7 --title "Williamson 6 (SFLT, ref 5)" --out ../figures/w6_energy_errors_SFLT.png
    python ../scripts/lauter_divplot.py --infile w6_div_norms_SFLT_ref5.txt --tmax 172800 --title "Williamson 6 (SFLT, ref 5)" --out ../figures/w6_div_norms_SFLT.png

Williamson 5 long-time energy, divergence and Casimirs (15 days):

    python ../scripts/make_longtime_plots.py --csv w5_diagnostics_pure.csv --prefix w5

SFLT energy conservation, amplitude sweep and seed ensemble (Williamson 6):

    python ../scripts/make_sflt_energy_plots.py --mode amp --prefix w6
    python ../scripts/make_sflt_energy_plots.py --mode ensemble --prefix w6

SFLT against deterministic overlay:

    python ../scripts/compare_sflt_pure_plot.py --sflt <sflt.txt> --pure <pure.txt> --tmax <seconds> --quantity {energy,div} --out <fig.png>

Scripts that write a `.png` without `--out` put it in `data/`. Plot options
(`--smooth`, `--color`, `--title`, ...) are listed by `--help`.

## Convergence tables

The convergence tables in `figures/*.tex` were typed from the analysis output
stored in `data/`:

| tables | numbers in `data/` |
|---|---|
| `lauter_spatial_*_table.tex`, `lauter_degree2_tables.tex`, `lauter_temporal_coords2_table.tex` | `lauter_spatial_*.txt`, `lauter_temporal_*.txt` |
| `w6_sflt_tables.tex`, `w6_convergence_tables.tex` | `w6_sflt_spatial.txt`, `w6_sflt_temporal.txt`, `w6_*_pure.txt` |

To regenerate the numbers, run the simulations with the library and then its
analysis scripts.

## Re-running the simulations

Clone the library and check out the commit used here:

    git clone https://github.com/colinjcotter/rsw_energy_conserving
    git -C rsw_energy_conserving checkout ed92c7f

Each `scripts/run_*.sh` then runs from that clone. Set two variables first (the
scripts read them at the top):

    export FIREDRAKE_VENV=~/firedrake          # your Firedrake environment
    export RSW_LIB=~/rsw_energy_conserving     # the library clone (this is the default)

The run scripts call the library's `scnv_analysis.py` and `tcnv_analysis.py`,
so they must run from the clone; `run_w5_*.sh` also call plot scripts from this
repository's `scripts/`. They write results to the clone's directory and
checkpoints to `../RSW_checkpoint/`. Each script header describes its study.

| Script | Result | Output numbers in `data/` |
|---|---|---|
| `run_scnv.sh` | W6 spatial convergence, SFLT, shared noise | `w6_sflt_spatial.txt` |
| `run_tcnv.sh` | W6 temporal convergence, SFLT (shared Brownian path) or `pure` | `w6_sflt_temporal.txt` (`pure` mode writes `w6_pure_temporal.txt`) |
| `run_w6_spatial.sh`, `run_ref5_w6_add.sh` | W6 spatial and temporal, deterministic, against a ref 6 reference | `w6_spatial_pure.txt`, `w6_temporal_pure.txt` |
| `run_lauter_determ.sh` | Läuter spatial and temporal error against the exact solution (writes `lauter_{spatial,temporal}_<bdm\|bdfm>.txt`; `BDFM=1` for the BDFM space) | `lauter_spatial_*.txt`, `lauter_temporal_*.txt` |
| `run_ref5_coords2.sh`, `run_tcnv_coords2.sh` | the same with quadratic geometry (`coords_degree=2`) | `lauter_spatial_coords2_full.txt`, `lauter_temporal_coords2.txt` |
| `run_degree2_conv.sh` | degree-2 robustness study | `lauter_spatial_deg2.txt`, `lauter_temporal_deg2.txt` |
| `run_ref4_vsexact_15day.sh`, `run_tcnv_numref_ref4.sh`, `run_tcnv_p2_ref3.sh` | further temporal studies (ref 5 vs exact, numerical reference at ref 4, P2 at ref 3) | `lauter_temporal_p1_ref5.txt`, `lauter_temporal_numref_ref4.txt`, `lauter_temporal_p2_ref3.txt` |
| `run_w6_exp34.sh` | SFLT amplitude sweep and 16-seed ensemble (diagnostics CSVs) | `w6_diag_amp_*.csv`, `w6_diag_ens_seed*.csv` |
| `run_w5_longtime.sh`, `run_w5_restore.sh` | W5 15-day long-time diagnostics | `w5_diagnostics_pure.csv` |
| `run_w5_finish.sh`, `run_w5_sflt.sh` | W5 5-day deterministic and strong-noise SFLT runs with VTK output | VTK, see below |
| `run_w6_compare.sh`, `run_w6_strong_viz.sh` | W6 2-day pure, SFLT and strong-noise runs with VTK output | VTK, see below |

The W5/W6 runs with `--diagnostics_every` write `w<case>_diagnostics_<SFLT|pure>.csv`;
several of the `data/` files are copies of these, renamed per figure.

## Vorticity and velocity comparison panels

The panels (`figures/*compare*`, `figures/w6_fig10_*`, `figures/w6_fig11_*`,
`figures/w5_fig19_*`, `figures/w6_sflt_vorticity.png`) are drawn from the VTK
output of the W5/W6 runs above. That output is tens of GB and is not stored in
this repository; re-run the corresponding `run_w5_*.sh` or `run_w6_*.sh`, then
`scripts/make_panels.sh` from the library clone (`make_compare_figs.py` needs the
`vtk` Python module). The Fig. 11 and strong-forcing Fig. 19 commands are
recorded exactly in `make_panels.sh`; the other panels use the same call with
different `.pvd` files.
