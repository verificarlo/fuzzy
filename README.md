# Comparing Noise Simulation Models for Evaluating Stability of Modeling in Neuroimaging

Gregory Kiar<sup>1,2</sup>, Tristan Glatard<sup>3</sup>

<sup>1</sup>1McGill BME, <sup>2</sup>MNI, <sup>3</sup>Concordia CS

## Introduction
- The numerical reproducibility of neuroimaging analyses is challenged by observations comparing results obtained with small data perturbations.
- In this paper, we measure the compare the uncertainty of neuroimaging pipelines using two forms of stability analysis: one-voxel perturbations, and Monte-Carlo arithmetic analyses.
- We evaluate the stability of structural connectome generation by performing simulations on a common deterministic tractography algorithm in diffusion MRI.

## Methods
- Diffusion MRI NKI-RS dataset
- Preprocessing done with FSL defaults
- Modeling connectivity with Dipy deterministic tracing

### Noise injection
- One-voxel noise:
  - Various noise strengths and injection locations
- MCA
  - Recompiling numpy with Verificarlo
  - All operations replaced by simulations
  
## Prospective Results
- Characterization of noise in various 1-voxel settings
- Comparison of mean of 1vox, MCA, and original graphs
- Comparison of computational efficiency for 1vox and MCA methods

## References
