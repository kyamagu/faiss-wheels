export NUMPY_INCLUDE=$(python -c 'import numpy as np; print(np.get_include())')
export $CFLAGS="-I$NUMPY_INCLUDE $CFLAGS"
