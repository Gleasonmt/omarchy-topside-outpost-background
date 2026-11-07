# Topside Outpost

An animated background for [Omarchy](https://omarchy.org). Dusk over the mesas: a radio mast blinking, a drone on patrol, a convoy crawling through the valley.

> **Animated with [omarchy-live-wallpaper](https://github.com/Gleasonmt/omarchy-live-wallpaper).**
> A background, not a theme: it goes with whatever theme you use.
![Topside Outpost, moving](media/topside-outpost.webp)

## Install

You need the [live-wallpaper plugin](https://github.com/Gleasonmt/omarchy-live-wallpaper), 1.2.0 or later.
Install the plugin and this background together:

```bash
omarchy plugin add https://github.com/Gleasonmt/omarchy-live-wallpaper --enable --yes
git clone --depth 1 https://github.com/Gleasonmt/omarchy-topside-outpost-background ~/.config/omarchy/live-backgrounds/topside-outpost && omarchy restart shell
```

If you've installed the plugin's optional `live-wallpaper` command, `live-wallpaper install https://github.com/Gleasonmt/omarchy-topside-outpost-background` does the second line for you.

Then pick **Topside Outpost** in Omarchy menu → Style → Background. It's offered under every theme,
including ones you install later. Update with `live-wallpaper update`, or `git pull` in that folder.

## Details mode

In details mode the picture stays still and only small details move. It uses the least power,
which makes it good on battery or if you want a calmer desktop. Turn it on with `live-wallpaper mode details`
(`battery-mode details` for battery only) or in Omarchy menu → Style → Live Wallpaper:

![Topside Outpost, details mode](media/topside-outpost-lite.webp)

## How it moves

The wallpaper is a GPU shader (`live/2-outpost.frag.qsb`, source in `src/`) drawn by the
[live-wallpaper plugin](https://github.com/Gleasonmt/omarchy-live-wallpaper);
`backgrounds/2-outpost.png` is a frame of it, used by the lock screen and when the plugin
isn't installed. It pauses while a window covers the screen. See the plugin's README
for frame rates and battery settings.

Original artwork. The look is inspired by films and games; no logos or characters
are used.

## Performance

Measured on a Dell Latitude 9520 (Intel Iris Xe graphics, 8 threads) driving a 3440×1440
monitor, plugged in, with the plugin's default 30 fps. The wallpaper pauses whenever a window
covers the screen, so these are the costs while it's actually visible:

| Mode | GPU used | Wallpaper CPU | Compositor CPU |
|---|---|---|---|
| Still (plugin off) | ~0% | 2% | 4% |
| **Details mode** | ~1.5% | 7% | 8% |
| **Topside Outpost** | ~10% | 7% | 7% |

*GPU used* is how busy the GPU was, weighted by its clock speed against its maximum
(1350 MHz here). *CPU* is a share of one core. On battery the plugin draws at half
resolution and 10 fps by default, which is lighter still (plugin 1.1.2 or later: run
`omarchy plugin update`). To draw at half resolution plugged in too, set
`"renderScale": 0.5` in `~/.config/omarchy/live-wallpaper.json` (see the
[plugin's README](https://github.com/Gleasonmt/omarchy-live-wallpaper)).

## Making changes

The scene is `src/<name>.frag` (with `src/common.glsl`): edit it, then run

```bash
tools/build.sh           # rebuilds live/, the still in backgrounds/
tools/build.sh --media   # also the animated previews in media/ (a few minutes)
```

and commit the results. `tools/check.sh` runs the same checks as the pull request CI
(the shader compiles for every GPU Omarchy runs on, and the files are in place; needs `glslang` and `jq` too). Needs `qt6-shadertools`, `qt6-declarative`, ImageMagick and
(for `--media`) ffmpeg. To try a change on your own desktop, run
`live-wallpaper update` after pushing, or copy the built files into
`~/.config/omarchy/live-backgrounds/topside-outpost/`.

## License

[MIT](LICENSE)
