# Built-in topographic data of a volcano
z <- volcano
x <- 10 * (1:nrow(z))
y <- 10 * (1:ncol(z))

persp(
  x, y, z,
  theta = 135, phi = 30,
  col = "brown", shade = 0.5,
  xlab = "X", ylab = "Y", zlab = "Height"
)
