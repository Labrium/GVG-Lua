# GVG: The next generation of vector graphics
An implementation of the GVG image file format specification, for use with the Löve2D framework.

GVG Specification: https://github.com/Labrium/GVG/

**NOTE: This implementation is in the beta development stage right now, so expect breaking changes. Documentation will be available soon.**

## Dependencies
 - [30log](https://github.com/Yonaba/30log/blob/master/30log.lua)
 - [uuid](https://github.com/Tieske/uuid/blob/master/src/uuid.lua)
 - [dkjson](https://github.com/LuaDist/dkjson/blob/master/dkjson.lua)

## Usage
```lua

local GVG = require("GVG")

local world
local player

function love.load()
	-- initialize GVG
	GVG.init("baseF.glsl", "baseV.glsl")
	GVG.loadShapesFromDirectory("Shapes")
	GVG.loadHullsFromDirectory("Hulls")

	world = GVG.Group()

	player = GVG.Shape("circle") -- "circle" shape type is made available from "/Shapes/circle.glsl"
	player.uniforms.radius = {10}

	world:add(player)
end

function love.update(dt)
	-- do whatever
	player.x = player.x + 1
	player.y = player.y + 1
end

function love.draw()
	world:draw()
end

```

## Supported Shapes
 - [x] Arc
 - [x] Circle
 - [x] Dot grid
 - [x] Equilateral triangle
 - [x] Grid
 - [x] Hexagon
 - [x] Line
 - [x] N-gon
 - [x] N-Star
 - [x] Pentagon
 - [x] Rectangle
 - [x] Strip
 - [x] Trapezoid
 - [x] Triangle
 - [ ] Quadratic bezier
 - [ ] Quadratic bezier segment
 - [ ] Box
 - [ ] Cross
 - [ ] Cut disc
 - [ ] Edge
 - [ ] Egg
 - [ ] Ellipse
 - [ ] Heart
 - [ ] Hexagram
 - [ ] Horseshoe
 - [ ] Hyperbola
 - [ ] Isosceles triangle
 - [ ] Moon
 - [ ] Octagon
 - [ ] Oriented box
 - [ ] Parabola
 - [ ] Parabolic segment
 - [ ] Parallelogram
 - [ ] Pie
 - [ ] Polygon
 - [ ] Quadratic circle
 - [ ] Rhombus
 - [ ] Rounded box
 - [ ] Rounded cross
 - [ ] Rounded X
 - [ ] Star
 - [ ] Star 5
 - [ ] Uneven capsule
 - [ ] Vesica

## Features
 - [x] Mathematically perfect rasterization on the GPU
 - [x] Modular shape type system
 - [x] Modular bounding box function system
 - [x] Comments
   - [x] Single line
   - [x] Multi-line
 - [x] Unit specification
   - [x] Pixels
   - [ ] Percent (maybe???)
   - [ ] Metric
   - [ ] Imperial/Customary
 - [x] Automatic filled/outline modes
 - [x] Analytical antialiasing
   - [ ] None
   - [x] Normal
   - [ ] Configurable Subpixel (not just standard rgb lcd layout)
 - [x] Groups
 - [ ] Shape combining functions
   - [ ] Union
   - [ ] Subtract
   - [ ] Intersect
   - [ ] Exclude
 - [ ] Level of Detail (based on the computed area of the bounding polygon)
 - [x] Font rendering
   - [ ] Font file support
     - [ ] FaceType.js JSON format
     - [ ] TrueType (.ttf) through Lua port of FaceType.js (maybe???)
     - [ ] All formats supported by FreeType 2 (included in Löve2D) through FFI (maybe???)
     - [ ] Custom shape-based font format (maybe???)
   - [x] Rendering modes
     - [x] Bitmap
     - [x] Bitmap SDF
     - [ ] Compound Analytical SDF
 - [ ] Shape batching/instancing (of the same shape type)
 - [x] Element referencing for reusing shapes/groups or scripting
   - [x] In-file referencing
   - [ ] Cross-file referencing
 - [ ] SVG backward compatibility
 - [ ] Embedded or referenced raster image support
 - [ ] Gradients
   - [ ] Linear
   - [ ] Radial
   - [ ] Conic
   - [ ] Shape
 - [ ] Effects
   - [ ] Drop/inset shadows/glow
   - [ ] Blur
   - [ ] Textured shapes (using raster images)
 - [ ] Animation support
   - [ ] Shape morphing
   - [ ] Transitions

## TODO
 - [x] Allow multiple parents per element
 - [ ] Allow DPI scaled units
 - [x] Migrate bounding functions to vertex shader bounding meshes
   - [x] Migrate SDF function coordinates from absolute screen-space to SDF centered, pixel-per-pixel (instead of 0 to 1) texture coordinates to facilitate batching
 - [x] Add support for group closure syntax
 - [x] Fix id reference name table
   - [x] Figure out how to handle conflicting ids (such as from different files or the same file imported multiple times)
     - solution: add " 2", " 3", etc., or allow an id prefix parameter.
 - [ ] Separate base shader into base and SDF evaluation line to allow multiple different SDFs to be evaluated in the same shader to allow combining operations
 - [ ] Figure out what (if included) the image resolution parameter in the header will do
 - [x] Figure out what to do about unit conversion
 - [x] Figure out syntax for combining shapes
   - [x] Figure out syntax for combining groups of shapes
     - solution: don't.
 - [ ] Figure out the best way to manage external files

### Unrealistic Goals
 - [ ] Non-uniform scaling
 - [ ] CPU rasterization backend
 - [ ] File conversion
   - [ ] From
     - [ ] PDF
     - [ ] SVG
   - [ ] To
     - [ ] PDF
     - [ ] SVG
 - [x] Function graphing
   - [x] 1D
   - [ ] 2D
 - [ ] Scrollable sections
 - [ ] Responsive layout (for text and shapes)
 - [ ] Dynamic text
 - [ ] Procedural shapes and/or raster images
 - [ ] Custom shaders
 - [ ] Embedded hyperlinks
 - [ ] Embedded HTML and/or Markdown
 - [ ] Embedded interactivity (scripting) and/or embedded UI elements
   - [ ] Dark mode support
   - [ ] HTTP support (!?!?)
 - [ ] Lighting and materials (!?!?)
 - [ ] Postprocessing (!?!?)
 - [ ] Physics (!?!?)
 - [ ] 3D (!?!?)
   - [ ] As a 2D texture
   - [ ] Containing 3D models

&nbsp;

## Projects Using GVG-Lua

 - [Hoog.io](https://github.com/CurbaiCode/Hoog.io/)

&nbsp;

# License

[GVG-Lua](https://github.com/Labrium/GVG-Lua) &copy; 2023 by [Labrium](https://github.com/Labrium) is licensed under [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International](https://creativecommons.org/licenses/by-nc-sa/4.0).

[![licensebuttons by-nc-sa](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-nc-sa/4.0)

Shape type [SDF functions](https://iquilezles.org/articles/distfunctions2d/) (in Shapes directory) are licensed under:
<details>
<summary>The MIT License</summary>

Copyright © 2020-2023 Inigo Quilez

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
</details>
