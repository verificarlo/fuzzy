from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

extensions = Extension("mca_ext", ["mca_ext.pyx"])

setup(name='Hello world app',
      ext_modules=cythonize(extensions,
                            compiler_directives={'language_level': '3'}))