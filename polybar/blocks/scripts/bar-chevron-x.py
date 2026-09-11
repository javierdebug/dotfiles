#!/usr/bin/env python3
"""Locate the tray chevron on the bar, in pixels from the bar's left edge.

Reads an xwd dump of the polybar window on stdin

    xwd -id <bar window> -silent | bar-chevron-x.py

and prints one number: the leftmost inked column of the right-hand module
block, which is the chevron - tray-expander is the first module in
modules-right. tray-toggle.sh needs that number to park the floating tray
window just to its left, and cannot get it from the config: the chevron heads a
right-aligned block, so its position slides with the rendered width of every
label to its right. A long weekday ("Wednesday 13:10" is 35px wider than
"Friday 13:10" in Lato 11) or a three-digit volume moves it by tens of pixels,
while tray-offset-x is a fixed distance from the bar's right edge.

The block is found by the moat around it rather than by recognising glyphs, so
nothing here has to know which modules the bar carries or what they render.
Inside a block no module sits more than ~30px from its neighbour, while the
empty bar between the centred window title and the right-hand block is hundreds
of pixels wide, so the widest run of background-coloured columns in the right
half of the bar is that moat and the first ink after it is the chevron.

Prints nothing when the bar holds no ink, when no run is wide enough to be a
moat, or when the dump cannot be read - the caller's cue to leave the tray
where the config put it.
"""

import struct
import sys
from collections import Counter

# A gap this wide cannot be the spacing between two modules of one block; the
# only thing on the bar that clears it is the empty stretch before the block.
MIN_MOAT = 60

# How far a column's colour has to be from the background, summed over r/g/b,
# before it counts as ink. Antialiased glyph edges are much further out than
# this; it only has to clear rounding noise in the capture.
INK = 30


def read_xwd(blob):
    """(width, height, bytes_per_pixel, stride, pixels) from an xwd dump."""
    if len(blob) < 100:
        raise ValueError("short header")
    head = struct.unpack(">25I", blob[:100])
    size, _ver, fmt, _depth, width, height = head[0:6]
    bpp, stride = head[11], head[12]
    ncolors = head[19]
    if fmt != 2:  # ZPixmap; xwd emits nothing else for a TrueColor visual
        raise ValueError("unsupported pixmap format %d" % fmt)
    if bpp not in (24, 32):
        raise ValueError("unsupported depth %d" % bpp)
    return width, height, bpp // 8, stride, blob[size + ncolors * 12 :]


def main():
    try:
        width, height, step, stride, px = read_xwd(sys.stdin.buffer.read())
    except (ValueError, struct.error):
        return 1

    # Only the right half is of interest, and starting there also keeps the
    # workspace dots and the left end of a long window title out of the way.
    first = width // 2
    cols = range(first, width)
    if not cols or height == 0:
        return 1

    def col(x):
        """The colours down one column, as (r, g, b) triples."""
        for y in range(height):
            p = y * stride + x * step
            yield px[p + 2], px[p + 1], px[p]

    bg, _ = Counter(c for x in cols for c in col(x)).most_common(1)[0]

    def inked(x):
        return any(
            abs(r - bg[0]) + abs(g - bg[1]) + abs(b - bg[2]) > INK
            for r, g, b in col(x)
        )

    # Walk left from the right edge and stop at the first wide gap: everything
    # crossed on the way is the block, and the column the walk stopped on is
    # its leftmost ink.
    block = None
    empty = 0
    for x in reversed(cols):
        if inked(x):
            block = x
            empty = 0
        else:
            empty += 1
            if empty >= MIN_MOAT and block is not None:
                print(block)
                return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
