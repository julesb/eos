
local primitives = {}

  function primitives.cube(dim)
    return {
      -- bottom square
      -- -- initial blank
      {x=-dim, y=-dim, z=-dim, r=0, g=0, b=0},

      {x=-dim, y=-dim, z=-dim, r=1, g=1, b=1},
      {x=-dim, y=-dim, z= dim,  r=1, g=1, b=1},
      {x= dim, y=-dim, z= dim, r=1, g=1, b=1},
      {x= dim, y=-dim, z=-dim,  r=1, g=1, b=1},
      ---- back to first point
      {x=-dim, y=-dim, z=-dim, r=1, g=1, b=1},

      -- first vertical happens

      -- top square
      {x=-dim, y= dim, z=-dim, r=1, g=1, b=1},
      {x=-dim, y= dim, z= dim,  r=1, g=1, b=1},
      {x= dim, y= dim, z= dim, r=1, g=1, b=1},
      {x= dim, y= dim, z=-dim,  r=1, g=1, b=1},

      ---- back to first point
      {x=-dim, y= dim, z=-dim, r=1, g=1, b=1},

      -- blank
      {x=-dim, y= dim, z=-dim, r=0, g=0, b=0},
      -- remaining three verticals
      -- 1
      {x=-dim, y= dim, z= dim, r=1, g=1, b=1},
      {x=-dim, y=-dim, z= dim, r=1, g=1, b=1},
      -- blank
      {x=-dim, y=-dim, z= dim, r=0, g=0, b=0},
      -- 2
      {x= dim, y=-dim, z= dim, r=1, g=1, b=1},
      {x= dim, y= dim, z= dim, r=1, g=1, b=1},
      -- blank
      {x= dim, y= dim, z= dim, r=0, g=0, b=0},
      -- 3

      {x= dim, y= dim, z=-dim, r=1, g=1, b=1},
      {x= dim, y=-dim, z=-dim, r=1, g=1, b=1},
      -- blank
      {x= dim, y=-dim, z=-dim, r=0, g=0, b=0}
    }
  end

  primitives.quad_verts = {
    {x=-1, y=-1, z=0, r=1, g=1, b=1.0},
    {x= 1, y=-1, z=0, r=1, g=1, b=1.0},
    {x= 1, y= 1, z=0, r=1, g=1, b=1.0},
    {x=-1, y= 1, z=0, r=1, g=1, b=1.0},
    {x=-1, y=-1, z=0, r=1, g=1, b=1.0},
  }


  function primitives.axis3d(dim)
    return {
      {x= 0.0, y=0, z=0, r=0, g=0, b=0}, -- blank
      {x= 0.0, y=0, z=0, r=1, g=0, b=0},
      {x= dim, y=0, z=0, r=1, g=0, b=0},
      {x= dim, y=0, z=0, r=0, g=0, b=0}, -- blank

      {x= 0, y= 0.0, z=0, r=0, g=0, b=0}, -- blank
      {x= 0, y= 0.0, z=0, r=0, g=1, b=0},
      {x= 0, y= dim, z=0, r=0, g=1, b=0},
      {x= 0, y= dim, z=0, r=0, g=0, b=0}, -- blank

      {x= 0, y=0, z= 0.0, r=0, g=0, b=0}, -- blank
      {x= 0, y=0, z= 0.0, r=0, g=0, b=1},
      {x= 0, y=0, z= dim, r=0, g=0, b=1},
      {x= 0, y=0, z= dim, r=0, g=0, b=0}, -- blank
    }
  end

  local tx = 3
  primitives.triangle_verts = {
    {x =tx+ 1, y = 0, z=0, r=1, g=0, b=1},
    {x =tx+ -0.5, y = 0.8660254037844386, z=0, r=1, g=0, b=1},
    {x =tx+ -0.5, y = -0.8660254037844386, z=0, r=1, g=0, b=1},
    {x =tx+ 1, y = 0, z=0, r=1, g=0, b=1}
  }


return primitives
