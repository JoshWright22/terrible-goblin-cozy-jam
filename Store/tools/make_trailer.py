# Cuts the store trailer from autoplay footage (tools/record_footage.ps1) with ffmpeg.
# Edit CLIPS to recut from new footage. Run from the project root: python Store/tools/make_trailer.py
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CAPTURE = ROOT / "builds/capture"
ART = ROOT / "Store/art"
OUT = ROOT / "builds/capture/slush_rush_trailer.mp4"
MUSIC = ROOT / "Assets/sfx/Smothie vibes.wav"

A = CAPTURE / "footage_20260926_071610.mp4"   # Summer 6 and 10
B = CAPTURE / "footage_20260926_073734.mp4"   # Summer 11, 16, 18

# (footage, start second, length)
CLIPS = [
    (B, 4.5, 3.5),     # Brain Freeze intro card
    (A, 34.5, 5.0),    # packing a blender for one order
    (B, 38.0, 6.0),    # three customers waiting
    (B, 77.0, 5.5),    # Double Trouble
    (B, 87.0, 5.0),    # big score popup
    (A, 64.0, 5.0),    # blend and serve
    (B, 129.0, 6.5),   # Summer Festival
]
TITLE_SECONDS = 3.0
END_SECONDS = 4.5
FADE = 0.35


def main():
    inputs = ["-loop", "1", "-t", str(TITLE_SECONDS), "-i", str(ART / "trailer_title_1920x1080.png")]
    lengths = [TITLE_SECONDS]
    for footage, start, length in CLIPS:
        inputs += ["-ss", str(start), "-t", str(length), "-i", str(footage)]
        lengths.append(length)
    inputs += ["-loop", "1", "-t", str(END_SECONDS), "-i", str(ART / "trailer_end_1920x1080.png")]
    lengths.append(END_SECONDS)
    inputs += ["-i", str(MUSIC)]

    parts = []
    for i in range(len(lengths)):
        parts.append(f"[{i}:v]scale=1920:1080,fps=60,format=yuv420p,setsar=1,settb=AVTB[v{i}]")
    last = "v0"
    offset = 0.0
    for i in range(1, len(lengths)):
        offset += lengths[i - 1] - FADE
        parts.append(f"[{last}][v{i}]xfade=transition=fade:duration={FADE}:offset={offset:.3f}[x{i}]")
        last = f"x{i}"
    total = sum(lengths) - FADE * (len(lengths) - 1)
    music = len(lengths)
    parts.append(f"[{music}:a]atrim=0:{total:.3f},afade=t=in:d=1,afade=t=out:st={total - 2.5:.3f}:d=2.5[a]")

    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *inputs,
        "-filter_complex", ";".join(parts), "-map", f"[{last}]", "-map", "[a]",
        "-c:v", "libx264", "-preset", "slow", "-crf", "17", "-pix_fmt", "yuv420p",
        "-c:a", "aac", "-b:a", "192k", "-movflags", "+faststart", str(OUT)], check=True)
    print(f"Saved {OUT} ({total:.1f}s)")


if __name__ == "__main__":
    main()
