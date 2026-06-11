# Cowboy Hat Plot in R
# ---------------------

# Define grid
x <- seq(-8, 8, length = 50)
y <- seq(-8, 8, length = 50)
r <- sqrt(outer(x^2, y^2, "+"))

# Define sombrero function (sin(r)/r)
z <- sin(r) / r

# Handle r=0 case (avoid NaN)
z[r == 0] <- 1

# Plot
persp(
  x, y, z,
  theta = 30, phi = 30,    # viewing angles
  expand = 0.5,             # vertical scale
  col = "tan",              # cowboy hat color
  shade = 0.5,
  ticktype = "detailed",
  xlab = "X", ylab = "Y", zlab = "sin(r)/r"
)
