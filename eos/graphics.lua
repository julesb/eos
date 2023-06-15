local graphics = {}

function graphics.create()
	return {
		paths = {},
	}
end

function graphics.line(g, p1, p2, col)
	table.insert(g.paths, p1.x)
	table.insert(g.paths, p1.y)
	table.insert(g.paths, col.r)
	table.insert(g.paths, col.g)
	table.insert(g.paths, col.b)

	table.insert(g.paths, p2.x)
	table.insert(g.paths, p2.y)
	table.insert(g.paths, col.r)
	table.insert(g.paths, col.g)
	table.insert(g.paths, col.b)

	table.insert(g.paths, p2.x)
	table.insert(g.paths, p2.y)
	table.insert(g.paths, 0)
	table.insert(g.paths, 0)
	table.insert(g.paths, 0)
	--table.insert(g.paths, out)
	return g
end

return graphics
