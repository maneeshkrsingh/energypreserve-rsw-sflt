# Energy-conserving stochastic RSW: numerical results

Scripts, raw numbers and figures for the numerical experiments of the paper on
the energy-conserving stochastic rotating shallow water equations (SFLT noise).
The simulation code is a separate library:

- https://github.com/colinjcotter/rsw_energy_conserving (these results were
  produced with `main` up to commit `ed92c7f`; the convergence analysis scripts
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
- `figures/` — the figures (`.png`) and LaTeX tables / figure wrappers (`.tex`)
- `scripts/` — plotting scripts and the shell scripts that ran the simulations

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

## Vorticity and velocity comparison panels

`figures/w5_compare_*.png`, `figures/w6_compare_*.png` and
`figures/w6_sflt_vorticity.png` are drawn from the VTK/PVD output of the
simulations with `scripts/make_compare_figs.py` (or `scripts/render_compare.py`
with ParaView's `pvbatch`). That output is tens of GB and is not stored here;
re-create it with the matching `scripts/run_w5_*.sh` / `scripts/run_w6_*.sh`.

## Simulation scripts

`scripts/run_*.sh` are the shell scripts that ran the simulations, kept as a
record. They were written for one machine: edit the Firedrake environment and
`cd ~/rsw_energy_conserving` lines at the top before using them.
