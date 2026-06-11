x <- seq(-10, 10, length = 50)
y <- seq(-10, 10, length = 50)
z <- outer(x, y, function(x, y) sin(sqrt(x^2 + y^2)))

persp(
  x, y, z,
  theta = 30, phi = 30,
  col = "lightblue", shade = 0.6,
  xlab = "X", ylab = "Y", zlab = "sin(r)"
)
