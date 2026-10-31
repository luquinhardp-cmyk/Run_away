"""Original short looping device cues; no external assets."""
from pathlib import Path
import math, random, struct, wave

root = Path(__file__).resolve().parents[1] / "assets/audio"
for name in ("radio", "alarm"):
    rng = random.Random(410)
    samples = []
    for i in range(44100):
        t = i / 22050
        fade = min(1, t * 30, (2 - t) * 30)
        if name == "radio":
            value = rng.uniform(-0.14, 0.14) + 0.08 * math.sin(t * 2 * math.pi * 170) * math.sin(t * 2 * math.pi * 7)
        else:
            value = 0.22 * math.sin(t * 2 * math.pi * (650 + 160 * math.sin(t * math.pi * 2)))
        samples.append(struct.pack("<h", int(value * fade * 32767)))
    with wave.open(str(root / (name + ".wav")), "wb") as out:
        out.setparams((1, 2, 22050, 0, "NONE", "not compressed"))
        out.writeframes(b"".join(samples))
