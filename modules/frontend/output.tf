output "sww_cloudfront_distribution" {
  value = aws_cloudfront_distribution.sww_distribution
}

output "southwestwatches_com_bucket" {
  value = aws_s3_bucket.southwestwatches_com
}
