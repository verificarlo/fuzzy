#!/usr/bin/env python3
"""Exercise Pillow's uninstrumented codecs, including CPUID dispatch in SDE."""
from io import BytesIO

from PIL import Image

image = Image.new('RGB', (128, 128))
image.putdata([((i * 13) % 256, (i * 29) % 256, (i * 71) % 256)
               for i in range(128 * 128)])
for format in ('JPEG', 'AVIF', 'PNG', 'WEBP', 'TIFF', 'JPEG2000'):
    buffer = BytesIO()
    image.save(buffer, format=format)
    buffer.seek(0)
    decoded = Image.open(buffer)
    decoded.load()
    assert decoded.format == format, (format, decoded.format)
    assert decoded.size == image.size, (format, decoded.size)
    assert decoded.mode == image.mode, (format, decoded.mode)
    # Lossless codecs also check pixel data; lossy codecs must produce a
    # nonconstant image so a no-op decoder cannot satisfy the probe.
    if format in ('PNG', 'TIFF', 'JPEG2000'):
        assert decoded.tobytes() == image.tobytes(), format
    else:
        assert all(low < high for low, high in decoded.getextrema()), format
    print(f'[PASS] Pillow {format} encode/decode', flush=True)
