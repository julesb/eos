local quat = {}

function quat.new(w, x, y, z)
    return {w=w, x=x, y=y, z=z}
end

function quat.normalize(q)
    local length = math.sqrt(q.w*q.w + q.x*q.x + q.y*q.y + q.z*q.z)
    return {w = q.w / length, x = q.x / length, y = q.y / length, z = q.z / length}
end

function quat.conjugate(q)
    return {w = q.w, x = -q.x, y = -q.y, z = -q.z}
end

function quat.multiply(q1, q2)
    return {
        w = q1.w*q2.w - q1.x*q2.x - q1.y*q2.y - q1.z*q2.z,
        x = q1.w*q2.x + q1.x*q2.w + q1.y*q2.z - q1.z*q2.y,
        y = q1.w*q2.y - q1.x*q2.z + q1.y*q2.w + q1.z*q2.x,
        z = q1.w*q2.z + q1.x*q2.y - q1.y*q2.x + q1.z*q2.w
    }
end

function quat.rotate(point, q)
    local p = {w=0, x=point.x, y=point.y, z=point.z}
    local q_conj = quat.conjugate(q)
    local q_p = quat.multiply(q, p)
    local q_final = quat.multiply(q_p, q_conj)
    return {x = q_final.x, y = q_final.y, z = q_final.z}
end

function quat.from_angle_axis(angle, axis)
    local half_angle = angle / 2
    local s = math.sin(half_angle)
    return {
        w = math.cos(half_angle),
        x = s * axis.x,
        y = s * axis.y,
        z = s * axis.z
    }
end

return quat
