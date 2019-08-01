# Comparing Noise Simulation Models for Evaluating Stability of Modeling in Neuroimaging

Gregory Kiar<sup>1,2</sup>, Tristan Glatard<sup>3</sup>

<sup>1</sup>1McGill BME, <sup>2</sup>MNI, <sup>3</sup>Concordia CS

## Introduction
- The numerical reproducibility of neuroimaging analyses is challenged by observations comparing results obtained with small data perturbations.
- In this paper, we measure the compare the uncertainty of neuroimaging pipelines using various forms of stability analysis:
  - one-voxel (epsilon) perturbations,
  - Monte-Carlo arithmetic analyses,
  - (time permitting) Operating system
- We evaluate the stability of structural connectome generation by performing simulations on two modelling + tracing algorithms commonly used in diffusion MRI:
  - Dipy 6-component tensor and EuDX (deterministic tracing)
  - Dipy ODF and probabilistic tracing.

## Methods
- Diffusion MRI NKI-RS dataset
- Preprocessing done with FSL defaults and not evaulated here

## Modeling
- Lower-order processing:
  - 6 component tensor model ("known" condition)
  - EuDX deterministic tracing
- Higher-order processing:
  - ODF
  - Probalistic tracing

### Noise injection
- One-voxel noise:
  - Various noise strengths and injection locations
- MCA
  - Recompiling cython libs with Verificarlo
  - (time permitting) Recompile blas+lapack with Verificarlo
  - Test both recommended precision bits (24, 53)
- OS
  - Centos 5
  - Centos 6
  - Ubuntu 16

## Prospective Results
- Figure 1
  - Violin plots of an output norm for each noise setting and both session- and subject-differences
- Figure 2
  - Compare distributions and mean results for multiple repeitions of equiv. 1-voxel noise and MCA executions
- Figure 3
  - Comparison of computational efficiency for 1-voxel and MCA methods

## References
