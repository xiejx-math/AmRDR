# AmRDR numerical experiments

This folder is a self-contained MATLAB package for the five editable numerical-experiment drivers used in the paper: real matrices, repeated right-hand sides, uniform random matrices, prescribed-spectrum matrices, and rank-deficient matrices.

## Requirements

- MATLAB R2022a or newer is recommended. The package was prepared against MATLAB R2022a.
- The Statistics and Machine Learning Toolbox is required by the experiment summaries and plots (`quantile`).
- Run `test_rdr` for the solver and sampling regression checks.
- No generated results are included. Each demo creates a uniquely named output folder under `results/editable/`.

## Run an experiment

1. Open MATLAB and set the current folder to this `AmRDR` folder.
2. Open one demo script and edit the parameter block near its top if needed.
3. Run that script. Run the five scripts individually; each script clears the MATLAB workspace when it starts.

| Script | Experiment |
| --- | --- |
| `demo_editable_real.m` | Real sparse matrices and the selected four-method comparison: RK, mRDR, AmRDR-I, and AmRDR-II. The default selection matches the real-matrix suite in `demo_config.m`. |
| `demo_editable_reuse.m` | Reuse a fixed matrix for the selected number of right-hand sides. |
| `demo_editable_uniform.m` | Uniform random matrices with entries in `[t,1]`. |
| `demo_editable_spectral.m` | Synthetic matrices with user-controlled dimensions, rank, and singular values. |
| `demo_editable_rank_deficient.m` | Synthetic rank-deficient matrices with user-controlled spectrum. |

The demo scripts expose matrix dimensions, rank/spectrum, volume sampler, trial count, stopping limits, and plotting/output options. In particular, set `settings.volumeSampler` to `'pair_cdf'` or `'diagonal_rejection'` to choose the volume-sampling implementation where that sampler is used.

## Output and plotting

Each run prints its output directory. The directory contains the frozen configuration, source snapshot, per-run CSV summaries, and MAT checkpoints/results. Synthetic, reuse, and rank-deficient demos can also create separate row-action and elapsed-time figures. The real-matrix demo prints comparison and mRDR-parameter tables in the MATLAB Command Window; it does not open figures by default.

To plot a saved benchmark later, use `demo_plot_comparison` with its `all_results.mat` file. Result folders are ignored by Git via `.gitignore`; keep them locally or archive selected results separately when needed.

## Bundled matrix data

The `data_AmRDR` directory contains the bundled real-matrix files. The default real-data experiment uses `cari`, `cage`, `mk9-b1`, `n4c5-b2`, `ch5-5-b2`, `D_8`, and `GL6_D_9`. The demo checks each local matrix identity and records its SHA-256 in the output inventory. Matrix metadata and attribution are available from the [SuiteSparse Matrix Collection](https://sparse.tamu.edu/).

See [CITATION.md](CITATION.md) for dataset attribution.

