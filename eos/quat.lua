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

function quat.dot(q1, q2)
  return q1.w*q2.w + q1.x*q2.x + q1.y*q2.y + q1.z*q2.z
end

function quat.slerp(q0, q1, t)
  local dot = quat.dot(q0, q1)
  -- If the dot product is out of range due to floating point error, clamp it
  if dot < -1 then dot = -1 elseif dot > 1 then dot = 1 end

  local theta = math.acos(dot) * t
  local sin_theta = math.sin(theta)
  local sin_theta_0 = math.sin((1 - t) * theta)
  local sin_theta_1 = sin_theta

  local s0 = sin_theta_0 / sin_theta
  local s1 = sin_theta_1 / sin_theta

  return {
    w = s0 * q0.w + s1 * q1.w,
    x = s0 * q0.x + s1 * q1.x,
    y = s0 * q0.y + s1 * q1.y,
    z = s0 * q0.z + s1 * q1.z
  }
end


return quat
