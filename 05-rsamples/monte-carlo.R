n <- 10000
x <- runif(n); y <- runif(n)
inside <- (x^2 + y^2) <= 1
plot(x, y, col=ifelse(inside, "blue", "red"), pch=20)
pi_est <- 4*mean(inside)
print(pi_est)
