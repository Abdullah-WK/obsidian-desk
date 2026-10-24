#!/usr/bin/env python3
"""Write fastfetch's Arch logo as a raw ANSI file with an iridescent sweep (ice blue → violet →
pink → peach) down its lines, the same hues as the prompt's username. Output:
~/.config/fastfetch/arch-iridescent.txt; the dots' config.jsonc points its logo at it."""
import colorsys, os, re, subprocess
out = os.path.expanduser("~/.config/fastfetch/arch-iridescent.txt")
raw = subprocess.run(["fastfetch", "--logo", "arch", "--structure", "none", "--pipe", "false"],
                     capture_output=True, text=True).stdout
lines = [re.sub(r"\x1b\[[0-9;]*m", "", l).rstrip() for l in raw.split("\n")]
while lines and not lines[0].strip(): lines.pop(0)
while lines and not lines[-1].strip(): lines.pop()
n = max(1, len(lines) - 1)
def rgb(i):
    h = (190 + i * 210 / n) % 360
    r, g, b = colorsys.hls_to_rgb(h / 360, 0.72, 0.6)
    return f"{int(r*255)};{int(g*255)};{int(b*255)}"
with open(out, "w") as f:
    for i, l in enumerate(lines):
        f.write(f"\x1b[1;38;2;{rgb(i)}m{l}\x1b[0m\n")
print(f"{out}: {len(lines)} lines")
