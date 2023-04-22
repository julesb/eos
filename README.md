# eos
Pure Data externals for generative lasershows

The eos library is a collection of Pure Data externals and abstractions designed for laser manipulation and control. Inspired by the concept of GEM for graphical rendering, eos aims to provide a similar level of ease and flexibility for working with laser systems in the Pure Data enviroment. The library offers a range of objects for generating, processing and transforming ILDA style point data. With eos, artists and developers have access to a comprehensive toolset for exploring the possibilities of laser-based art and applications.


## Requirements
- [Helios Laser DAC](https://bitlasers.com/helios-laser-dac/)
- [Pure Data](https://puredata.info/)
- [pd_helios (julesb fork)](https://github.com/julesb/pd_helios)
- [pd-lua](https://github.com/agraef/pd-lua)
- [helios-control](https://github.com/julesb/helios-control)


## Reference

### Core

### `analyze`

### `composite`

### `denormalize`

### `eoshead`

### `normalize`

### `render`

The `render` object transforms raw point data into a format suitable for sending to the laser DAC. It can perform subdivision, inserting new points along the path between input points so that the galvo moves with a controlled trajectory between the points. This type of conditioning is usually required in order to prevent the galvo overshooting corner positions. It inserts dwell points at the provided points which provides sharp corners.

#### Inlets

1. **Points data (XYRGB format):** Input raw point data in XYRGB format.
2. **Control messages:** Input messages to control the object's parameters.

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

- **`dwell`** Integer. Sets the number of dwell points to insert at corners. *Note: Angle dependent optimization is currently under development.*

- **`subdivide`** Integer. Specifies the largest distance that the galvo is allowed to travel without subdivision points (ballistic motion). Smaller values create more subdivision points, creating a more precise and stable image, potentially at the cost of reduced frame rate. Distances are in "screen space" - i.e., with a 16-bit DAC, the screen will have a width and height of 4096 points. Typical values are between 16 to 64, but it will depend on the content.

- **`preblank`** Integer. Inserts extra blank points at the end of a blank travel, before turning the laser on, with the intention of preventing a "pre-tail" that can occur if the galvo is still traveling when the signal to turn the laser on is received. This approach is somewhat hackish.


### `xyrgb-file`


## Color

### `color`

The `color` object applies a color to the incoming points based on the specified color mode, which can be RGB, HSV, or a named color.

### Inlets

1. **List (XYRGB format):** Input point data in XYRGB format.
2. **Float:** R (in RGB mode) or H (in HSV mode) color component.
3. **Float:** G (in RGB mode) or S (in HSV mode) color component.
4. **Float:** B (in RGB mode) or V (in HSV mode) color component.

### Outlets

1. **List (XYRGB format):** Output point data with modified colors in XYRGB format.

### Arguments

The creation arguments set the initial values for the color mode and color components. The arguments are positional and are all optional.

- **`mode`** or **`named color`** The color mode or a named color. Valid values are "rgb", "hsv", or a named color.
- **color_component_1:** R (in RGB mode) or H (in HSV mode) color component (range 0 .. 1).
- **color_component_2:** G (in RGB mode) or S (in HSV mode) color component (range 0 .. 1).
- **color_component_3:** B (in RGB mode) or V (in HSV mode) color component (range 0 .. 1).

#### Examples

`color blue`
`color rgb 0.1 0.1 0.9`
`color hsv 0.5 1 1`

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

### Messages

- **list** `<list>`: Takes in a list of point data in XYRGB format and outputs a new list of point data with modified colors based on the specified color mode and color components.


### `colorcurves`

### `gradient`

### `ttlcolor`

### `rangemap`


## Primitive

### `point`

### `polygon`


## Transform

### `rotate`

### `scale`

### `symmetry`

### `translate`


## Other

### `colorscan`

### `triggers`

### `fadecircle`

### `flock`

### `noisemod`

### `phasetunnel`

### `presets`

### `qix`

### `traildot`

### `xygizmo`

### `zoombots`
