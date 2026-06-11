steps <- 1000
walk <- cumsum(sample(c(-1,1), steps, replace=TRUE))
plot(walk, type="l", main="Random Walk", col="blue")
