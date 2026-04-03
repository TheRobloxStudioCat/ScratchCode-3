local hitbox = {}

local cur_offset_x, cur_offset_y = 0,0

function hitbox.IsTouching(det_x1,det_y1,x,y,xs,ys)
    local det_x = det_x1 - cur_offset_x
    local det_y = det_y1 - cur_offset_y

    local isTouchX = det_x >= x and det_x <= (x + xs)
    local isTouchY = det_y >= y and det_y <= (y + ys)

    return isTouchX and isTouchY
end

function hitbox.SetOffset(x,y)
    cur_offset_x, cur_offset_y = x, y
end

return hitbox