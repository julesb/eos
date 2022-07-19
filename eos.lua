local eos = {}

function eos.addpoint(arr, x, y, r, g, b, numpoints)
    if numpoints == nil or numpoints < 1 then numpoints = 1 end
    for i=1,numpoints do
        table.insert(arr, x)
        table.insert(arr, y)
        table.insert(arr, r)
        table.insert(arr, g)
        table.insert(arr, b)
    end
end


return eos
