#include <stdio.h>

// Prototypes des fonctions BLAS et LAPACK
extern void dgemm_(const char *transa, const char *transb, const int *m,
                   const int *n, const int *k, const double *alpha,
                   const double *a, const int *lda, const double *b,
                   const int *ldb, const double *beta, double *c,
                   const int *ldc);

extern void dgesv_(const int *n, const int *nrhs, double *a, const int *lda,
                   int *ipiv, double *b, const int *ldb, int *info);

// Fonction pour générer une matrice de Hilbert
void generate_hilbert_matrix(double *matrix, int n) {
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < n; j++) {
      matrix[i * n + j] = 1.0 / (i + j + 1);
    }
  }
}

void test_dgemm() {
  // Dimensions des matrices
  int m = 3, n = 3, k = 3;

  // Génération des matrices de Hilbert
  double a[9];
  generate_hilbert_matrix(a, 3);
  double b[9];
  generate_hilbert_matrix(b, 3);
  double c[9] = {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0};

  // Constantes pour la routine BLAS
  double alpha = 1.0;
  double beta = 0.0;

  // Dimensions principales
  int lda = 3, ldb = 3, ldc = 3;

  // Appel de la routine BLAS
  dgemm_("N", "N", &m, &n, &k, &alpha, a, &lda, b, &ldb, &beta, c, &ldc);

  // Affichage du résultat
  printf("dgemm:\n");
  for (int i = 0; i < m; i++) {
    for (int j = 0; j < n; j++) {
      printf("%.13a ", c[i * n + j]);
    }
    printf("\n");
  }
}

void test_dgesv() {
  // Dimension de la matrice
  int n = 3, nrhs = 1;

  // Génération de la matrice de Hilbert
  double a[9];
  generate_hilbert_matrix(a, 3);

  // Vecteur de droite (b)
  double b[3] = {1.0, 1.0,
                 1.0}; // Vous pouvez aussi générer ce vecteur dynamiquement

  // Indices de pivot
  int ipiv[3];

  // Dimensions principales
  int lda = 3, ldb = 3;

  // Variable d'information
  int info;

  // Appel de la routine LAPACK
  dgesv_(&n, &nrhs, a, &lda, ipiv, b, &ldb, &info);

  if (info == 0) {
    // Affichage du résultat
    printf("dgesv:\n");
    for (int i = 0; i < n; i++) {
      printf("%.13a ", b[i]);
    }
    printf("\n");
  } else {
    printf("dgesv a échoué avec info = %d\n", info);
  }
}

int main() {
  test_dgemm();
  test_dgesv();
  return 0;
}
