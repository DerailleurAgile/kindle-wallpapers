# kindle-wallpapers

Tooling for making KOReader sleep-screen wallpapers that actually look right on
a 16-level e-ink panel. `mkwall` takes ordinary images and emits exact-size,
8-bit grayscale, alpha-free PNGs.

```sh
mkwall sources/                        # whole folder -> out/
mkwall --levels 16 --dither sources/   # bake a panel-accurate dither
mkwall --fit pad --bg white sources/   # letterbox instead of centre-crop
```

## Target device

Defaults are for a **Kindle Paperwhite 3 (7th gen, 2015)**:

| Spec | Value |
| ---- | ----- |
| Panel resolution | 1072 × 1448 px (portrait, W × H) |
| Aspect ratio | ~0.74 (1:1.351) |
| Density | 300 ppi (6") |
| Gray levels | 16, despite the 8-bit framebuffer |

`mkwall --list-devices` has presets for other Kindles; `--size WxH` handles
anything not listed.

## What KOReader wants

- **PNG or JPG.** PNG is better — lossless, no JPEG noise around text or line
  art, and a small 8-bit-gray PNG decodes faster on wake than a big JPEG.
- **8-bit grayscale, no alpha channel.** Metadata and ICC profiles do nothing
  here but add bytes.
- **Exact panel dimensions.** KOReader will scale for you, but its scaler
  softens fine detail at 300 ppi, so pre-sizing is visibly sharper.
- **No animation** — only a GIF's first frame is ever shown.
- Keep each file under ~1 MB so wake stays snappy. `mkwall` warns past that.

## Installation

Requires Bash and ImageMagick 7 (the `magick` command). No Python, no
`pip install`.

```sh
git clone https://github.com/DerailleurAgile/kindle-wallpapers.git
cd kindle-wallpapers
```

Then put `mkwall` on your `PATH`. A symlink keeps it in sync with the repo, so
`git pull` is all it takes to update:

```sh
mkdir -p ~/.local/bin
ln -s "$PWD/mkwall" ~/.local/bin/mkwall
```

## Workflow

1. Drop source images into `sources/` (both `sources/` and `out/` are
   gitignored — this repo tracks the tooling, not the artwork).
2. `mkwall sources/` — check the results in `out/`.
3. Copy to the Kindle over USB:

   ```sh
   cp out/*.png /run/media/$USER/Kindle/koreader/screensaver/
   ```

4. In KOReader: **gear (⚙) → Screen → Sleep screen → Wallpaper**, then either
   *custom image* (one file) or *random image from folder*. Turn off the
   overlays nearby (book cover, message, "Sleeping" text) for a designed
   wallpaper.

Any readable path works for step 3; `/mnt/us/koreader/screensaver` is just the
convention. On Kindle, KOReader lives at `/mnt/us/koreader`.

> KOReader's sleep screen only applies when the device suspends **from inside
> KOReader**. Back out to the Kindle home screen and you get Amazon's native
> screensaver instead.

## Options

| Option | Effect |
| ------ | ------ |
| `-d, --device NAME` | device preset (default: `pw3`); see `--list-devices` |
| `-s, --size WxH` | explicit pixel size, overrides `--device` |
| `-o, --outdir DIR` | output directory (default: `out`) |
| `--fit MODE` | `crop` (fill + centre-crop, default), `pad`, `stretch` |
| `--gravity DIR` | which part a crop keeps: `center` (default), `north`, `south`, `east`, `west`, or a corner |
| `--gamma N` | `>1` opens shadows, e.g. `1.6` for dark art (default: `1.0`) |
| `--bg COLOR` | pad colour (default: `white`) |
| `--bc AxB` | brightness-contrast, or `none` (default: `5x8`) |
| `--levels N` | quantize to N gray levels, `0` = off (default: `0`) |
| `--dither` | Floyd-Steinberg when quantizing (default: off) |
| `--jpg` | write JPEG instead of PNG |
| `-q, --quality N` | JPEG quality (default: `92`) |
| `--landscape` | swap width and height |
| `-f, --force` | overwrite existing outputs |
| `-n, --dry-run` | show what would be done |
| `--quiet` | only report problems |

Inputs can be files or directories (directories are scanned one level deep).
JPEG, PNG, TIFF, WebP, BMP, GIF, HEIC, AVIF, SVG and PDF all work as sources.

## Per-image tuning

One pass over a folder gets you usable files, but the three source types want
different treatment. Worked examples:

```sh
# Dark painted art: open the shadows, dither the smoke gradients.
mkwall --gamma 1.6 --levels 16 --dither sources/box-art.jpg

# Pen-and-ink plate: full 8-bit ramp, no dither — noise dirties clean paper.
mkwall sources/creatures.jpeg

# Flat-tone poster with a title: anchor the crop so the type survives.
mkwall --gravity north --levels 16 --dither sources/poster.jpg
```

Two things worth checking before you commit to a batch:

- **Where the crop lands.** `mkwall` only warns past 15% loss, which is late if
  the missing 10% is a headline. Compare source and target aspect first —
  `magick identify -format '%f %wx%h ar=%[fx:w/h]\n' sources/*` against the
  panel's 0.740 — and reach for `--gravity` or `--fit pad` when it matters.
- **How dark the result is.** `magick identify -format '%f mean=%[fx:int(mean*255)]\n' out/*.png`
  — anything with a mean much under 100 will read as a murky slab on e-ink and
  wants `--gamma`.

## Design notes for this panel

- **16 gray levels, not 256.** Smooth gradients band visibly. Either embrace
  flat tones and hard edges, or dither deliberately with
  `--levels 16 --dither` rather than letting the device decide.
- **Dither costs nothing on painted art and hurts line art.** Pen-and-ink on
  white paper has almost no gradients to smooth, so error diffusion just
  speckles the background.
- **E-ink reads darker than a monitor** — midtones close up. The default
  `--bc 5x8` lifts them a little; tune per image. Keep true black for accents
  only, since large black fields ghost into the next refresh.
- **Thin light-gray hairlines disappear.** Use strokes of 2 px or more and keep
  line art at 30% gray or darker.
- **Text needs ~24 px minimum** at this resolution, and no hairline weights.

## Notes

- `--levels` quantizes by remapping onto a generated N-step ramp rather than
  using ImageMagick's `-colors`, which picks its own palette and leaks extra
  levels through Q16 rounding. The ramp is exactly the evenly-spaced set the
  panel can show (0, 17, 34, … 255 for 16 levels).
- `--levels 16 --dither` usually produces a *larger* PNG than no dithering at
  all — dither noise doesn't compress. It's worth it on gradients and not much
  else.
- Transparency is flattened onto `--bg` (white by default) before grayscaling,
  so PNG logos don't come out on a black field.
