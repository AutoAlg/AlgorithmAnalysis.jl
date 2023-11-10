mutable struct Point
  is_leaf
end

"Add two points."
function +(p1::Point, p2::Point)::Point
    
end

"Negate a point."
function -(p::Point)::Point
  
end

"Inner product of two points."
function *(p1::Point, p2::Point)::Real
  
end

"Squared norm of a point."
squared_norm(p::Point)::Real = p*p

