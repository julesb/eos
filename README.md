# eos
Pure Data externals for generative lasershows

The eos library is a collection of Pure Data externals and abstractions designed for laser manipulation and control. Inspired by the concept of GEM for graphical rendering, eos aims to provide a similar level of ease and flexibility for working with laser systems in the Pure Data environment. The library offers a range of objects for realtime generation, processing and transforming of ILDA style point data. With eos, artists and developers have access to a comprehensive toolkit for exploring the possibilities of laser-based art and applications.

The eos toolkit includes:
- Pd externals built on [pd-lua](https://github.com/agraef/pd-lua), covering geometric primitives, transforms, geometry and color modulation, color manipulation, compositing and rendering, ILDA file loading and playback,  plus a collection of generative objects - flocking, spirograph/xy gizmo, phase tunnel, scan modulation...
- Pd abstractions. Some of the eos externals have a corresponding control panel built as a Pd abstraction. For example patch a `render-control` object into inlet 2 on a `render` object, and you have an instant UI for the `render` object. 
- eos lua libraries. With the eos lua libraries available in a project, you can easily create your own laser effects Pd externals with little boilerplate, and lots of examples to learn and build from.
- Sandbox environment. `eos-sandbox.pd` is a Pd patch with many sub-patches which provides working examples for all of the eos objects. The sandbox patch itself also serves as an example of how to set up multiple visual generating sub-patches running concurrently.
- Presets system. This is a generic presets system which is easy to integrate into a patches control panel. Saving a preset writes all of the control panels variables to file named with the preset name. Loading a preset from file restores all of the variables and control panel UI state. Browse saved presets using the `prev` and `next` buttons.
- [`pd_helios` (julesb fork)](https://github.com/julesb/pd_helios) and [`helios-control`](https://github.com/julesb/helios-control). An enhanced version of [pd_helios](https://github.com/timredfern/pd_helios) that adds dynamic PPS control, transforms, color controls, geometric correction, low level DAC features. The full featured control panel makes it easy to control all settings from within Pd.

## Requirements
- [Helios Laser DAC](https://bitlasers.com/helios-laser-dac/)
- [Pure Data](https://puredata.info/)
- [pd_helios (julesb fork)](https://github.com/julesb/pd_helios)
- [pd-lua](https://github.com/agraef/pd-lua)
- [helios-control](https://github.com/julesb/helios-control)

## Installation
Install the requirements listed above.

Add the `eos` directory in this repo to your Pd path: File->Preferences->Path->Add.

Add the `eos` directory in this repo to your LUA_PATH environment variable:

`export LUA_PATH=<your-path>/eos/'?.lua;;'`

Add the above line to your .bashrc or similar to make it permanent.


## Reference

### Index

#### Core
- [analyze](#analyze)
- [composite](#composite)
- [denormalize](#denormalize)
- [eoshead](#eoshead)
- [ilda-file](#ilda-file)
- [normalize](#normalize)
- [render](#render)
- [xyrgb-file](#xyrgb-file)

#### Color
- [color](#color)
- [colorcurves](#colorcurves)
- [colorscan](#colorscan)
- [gradient](#gradient)
- [ttlcolor](#ttlcolor)
- [rangemap](#rangemap)

#### Primitive
- [point](#point)
- [polygon](#polygon)

#### Transform
- [rotate](#rotate)
- [scale](#scale)
- [symmetry](#symmetry)
- [translate](#translate)

#### Other
- [triggers](#triggers)
- [fadecircle](#fadecircle)
- [flock](#flock)
- [noisemod](#noisemod)
- [phasetunnel](#phasetunnel)
- [presets](#presets)
- [qix](#qix)
- [traildot](#traildot)
- [xygizmo](#xygizmo)
- [zoombots](#zoombots)


### Core

### `analyze`

Generate frame stats.

...

 
### `composite`

Combine multiple visual elements into a frame.

...

 
### `denormalize`

Internally eos coordinates and color components range from -1 to 1, or from 0 to 1. `denormalize` maps points to 12 bit full scale screen coordinates from -2047 to 2047. Colors are similarly mapped to the range 0 to 255. This is the format that the DAC expects.

Most eos patches should have a `denormalize` as the last stage in the pipeline before the DAC.

...

### `eoshead`

A simple utility object which is used to reduce the amount of patching required when combining multiple image generating subpatches in a master patch.

...

### `ilda-file`

Load and play ILDA files.

...

### `normalize`

Internally eos coordinates and color components range from -1 to 1, or from 0 to 1. `normalize`can be used if you want to specify geometry in screen coordinates ranging from -2047 to 2047. Run your data through `normalize` before patching to any eos object inlets. Colors are similarly mapped from a 0 to 255 range to a 0 to 1 range. [see `denormalize`]  

...

### `render`

The `render` object transforms raw point data into a format suitable for sending to the laser DAC. It can perform subdivision, inserting new points along the path between input points so that the galvo moves with a controlled trajectory between the points. This type of conditioning is usually required in order to prevent the galvo overshooting corner positions. It inserts dwell points at the provided points which provides sharp corners.

#### Inlets

1. **Points data** Input raw point data in XYRGB format.
2. **Control messages** Input messages to control the object's parameters.

#### Outlets

1. **Processed points data:** Output points data in a format suitable for sending to the DAC.
2. **Number of output points:** Output the number of points generated by the object.

#### Arguments

- mode
- dwell
- subdivide
- preblank

The creation arguments set the initial values for these parameters. See the Messages section for details. The arguments are positional and are all optional. For example ```render lines 4 16``` will create a ```render``` object in lines mode with dwell=4, subdivide=16. Preblank will be set to a default value.  

#### Messages

- **`mode`** Symbol. Valid values are either `points` or `lines`.
  - `points` In points mode, all subdivision points will have a color of [0, 0, 0], meaning the input points will be drawn with no lines connecting them.
  - `lines` In lines mode, subdivision points will inherit the color of the point before the subdivision points, rendering a line between the points.

- **`dwell`** Integer. Sets the number of dwell points to insert at corners.

- **`subdivide`** Integer. Specifies the largest distance that the galvo is allowed to travel without subdivision points (ballistic motion). Smaller values create more subdivision points, creating a more precise and stable image, potentially at the cost of reduced frame rate. Distances are in "screen space" - i.e., with a 16-bit DAC, the screen will have a width and height of 4096 points. Typical values are between 16 to 64, but it will depend on the content.

- **`preblank`** Integer. Inserts extra blank points at the end of a blank travel, before turning the laser on, with the intention of preventing a "pre-tail" that can occur if the galvo is still traveling when the signal to turn the laser on is received.


### `xyrgb-file`

Loads frames from a `.xyrgb` file. These are a simple ascii files containing frame data extrated from ILDA files. Each line contains all of the points in a frame, in the format X Y R G B X Y R G B etc. Send a `bang` to inlet 1 and it will output the next frame. 

## Color

### `color`

The `color` object applies a color to the incoming points based on the specified color mode, which can be RGB, HSV, or a named color.

#### Inlets

1. **List** Input point data in XYRGB format.
2. **Float** R (in RGB mode) or H (in HSV mode) color component.
3. **Float** G (in RGB mode) or S (in HSV mode) color component.
4. **Float** B (in RGB mode) or V (in HSV mode) color component.

#### Outlets

1. **List** Output point data with modified colors in XYRGB format.

#### Arguments

The creation arguments set the initial values for the color mode and color components. The arguments are positional and are all optional.

- **`mode`** or **`named color`** The color mode or a named color. Valid values are "rgb", "hsv", or a named color.
- **color_component_1** R (in RGB mode) or H (in HSV mode) color component (range 0 .. 1).
- **color_component_2** G (in RGB mode) or S (in HSV mode) color component (range 0 .. 1).
- **color_component_3** B (in RGB mode) or V (in HSV mode) color component (range 0 .. 1).

#### Messages

None

#### Named colors

`black`
`grey`
`red`
`orange`
`yellow`
`green`
`cyan` 
`blue`
`purple` 
`violet`
`magenta`
`white`

#### Examples

`color blue`
`color rgb 0.1 0.1 0.9`
`color hsv 0.5 1 1`


### `colorcurves`

Color correction. Get closer to a linear color response when using an RGB laser module that has inherent nonlinear response curves. Use three Pd arrays to specify R G B color response curves.  

### `colorscan`

Applies sinusoidal or square wave color modulation over the input points. Each color channel has its own frequency, amplitude and phase parameters.

...

### `gradient`

Applies a color gradient over the input points. Two gradient endpoint colors are specified in HSV format.

...

### `ttlcolor`

Color module to use when using a laser with TTL color modulation only.

...

### `rangemap`

Color range mapping. For example map RGB components range from 0 to 1 to the range 0.5 to 1. Useful if your lasers response drops off quickly in the lower color range. 

...

## Primitive



### `point`

Generates a single point with XY coordinates and default color white.

...

### `polygon`

Generates a n-sided polygon in XYRGB format.

`polygon nsides radius stride`

...

## Transform


### `rotate`

Rotate points.

...

### `scale`

The `scale` object scales incoming points in both the x and y axes as well as adjusting the individual RGB color components.

#### Inlets

1. **List** Input point data in XYRGB format.
2. **Float** Scaling factor for the x-axis.
3. **Float** Scaling factor for the y-axis.

#### Outlets

1. **List** Output point data with modified scale and color components in XYRGB format.

#### Arguments

The creation arguments set the initial values for the scaling factors and color component multipliers. The arguments are positional and are all optional.

- **x_scale** Scaling factor for the x-axis.
- **y_scale** Scaling factor for the y-axis.
- **r_scale** Multiplier for the R color component.
- **g_scale** Multiplier for the G color component.
- **b_scale** Multiplier for the B color component.

### Messages

None


### `symmetry`

Duplicate points with n-fold rotational symmetry.

...

### `translate`

Translate points


## Other

### `triggers`

A framework for creating animation sequences that can be triggered on demand. When a sequence is triggered repeatedly more quickly than the duration of the sequence, then sequences begin to overlap. A new instance of the sequence, on its own timeline, is created for each trigger event. The results of all the active sequences are composited into a single visual.

...

### `fadecircle`

This is a simple one-shot visual sequence intended to be used in the `triggers` framework. Draws a circle that starts as a point and grows, fading to black as the radius increases.

...

### `flock`

Classic flocking algorithm with extensions - lots of parameters.

...

### `noisemod`

Simplex noise based position modulation.

...

### `phasetunnel`

A trippy tunnel effect.

...

### `presets`

This is a generic presets system which is easy to hook into a patches control panel. Save and load named presets. Browse saved presets using the `prev` and `next` buttons. 

...

### `qix`

A line, under the influence of simplex noise, leaving trails. Based on (my memory of) the classic game Qix.

...

### `traildot`

A singular bright beam moves gracefuly through the air, leaving frozen sheets of ice in its wake.

...

### `xygizmo`

Classic spiro / sinusoidal modulator.

...

### `zoombots`

Beams are independant agents with their own behaviour, living within a simulation.

...



## Ref doc template
```
### `<objectname>`

<description>

#### Inlets

1. **<type>** <desc>

...

#### Outlets

1. **<type>** <desc>

...

#### Arguments

...

#### Messages

...
```
