x <- seq(-2, 2, length = 50)
y <- seq(-2, 2, length = 50)
z <- outer(x, y, function(x, y) x^2 - y^2)

persp(
  x, y, z,
  theta = 45, phi = 20,
  col = "lightgreen", shade = 0.5,
  xlab = "X", ylab = "Y", zlab = "x^2 - y^2"
)
