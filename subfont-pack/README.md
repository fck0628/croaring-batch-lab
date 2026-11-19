# subfont-pack: the wrong glyph under the right font name

Two one-second MKVs contain the same subtitle, video and attachment filename. The second font maps “o” to the glyph for “x”. Both fonts still report the same family and PostScript name. On the recorded run libass logged DejaVuSans for both, while all five rendered frames differed.

## Reproduce on Linux

Install FFmpeg with libass, Python 3 with fontTools, and DejaVu Sans. Clone the branch and run:

```sh
git clone --depth 1 --branch subfont-pack-repro https://github.com/fck0628/croaring-batch-lab.git
cd croaring-batch-lab/subfont-pack
sh reproduce.sh
```

The script builds both MKVs offline, isolates system fonts, prints both selection logs and checks the five frame hashes. It prints the directory containing the clips and hash files. Open the clips and look at the first letter of “office”. Use DEJAVU_FONT to specify a different installation path for DejaVuSans.ttf.

[Recorded output](run.log) · [Renderer version](renderer-version.txt) · [Fixture source](test.ass) · [Reproduction script](reproduce.sh)

This standalone fixture is the first regression case for the proposed subfont-pack CLI.
