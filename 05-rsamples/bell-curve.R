x <- seq(-4, 4, length = 50)
y <- seq(-4, 4, length = 50)
z <- outer(x, y, function(x, y) exp(-(x^2 + y^2)))

persp(
  x, y, z,
  theta = 30, phi = 30,
  expand = 0.6,
  col = "skyblue", shade = 0.6,
  xlab = "X", ylab = "Y", zlab = "exp(-r^2)"
)
