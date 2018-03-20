resource "aws_s3_bucket" "top_domain" {
  bucket = "andrewjohnperry.com"
  acl    = "public-read"
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket" "logs" {
  bucket = "ajp-logs"
}


resource "aws_s3_bucket_policy" "top_domain_policy" {
  bucket = "${aws_s3_bucket.top_domain.id}"
  policy =<<POLICY
{
  "Version":"2012-10-17",
  "Statement":[{
	"Sid":"PublicReadGetObject",
        "Effect":"Allow",
	  "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::${aws_s3_bucket.top_domain.id}/*"
      ]
    }
  ]
}
POLICY
}

data "aws_acm_certificate" "top_level" {
  domain   = "andrewjohnperry.com"
  types = ["AMAZON_ISSUED"]
  most_recent = true
  provider = "aws.virginia"
}


resource "aws_cloudfront_distribution" "top_level" {
  origin {
    domain_name = "${aws_s3_bucket.top_domain.bucket_domain_name}"
    origin_id   = "topLevelDomainOrigin"

  }

  enabled             = true
  is_ipv6_enabled     = true

  comment             = "CDN for top level domain"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.logs.bucket_domain_name}"
    prefix          = "cloudfront/top_domain"
  }

  aliases = ["www.${aws_s3_bucket.top_domain.id}", "${aws_s3_bucket.top_domain.id}"]

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "topLevelDomainOrigin"
    compress = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = "${data.aws_acm_certificate.top_level.arn}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1_2016"
  }
}

data "aws_route53_zone" "top_level" {
  name = "andrewjohnperry.com."
}

resource "aws_route53_record" "top_level" {
  zone_id = "${data.aws_route53_zone.top_level.zone_id}"
  name    = "${data.aws_route53_zone.top_level.name}"
  type = "A"
  alias {
    name = "${aws_cloudfront_distribution.top_level.domain_name}"
    zone_id = "${aws_cloudfront_distribution.top_level.hosted_zone_id}"
    evaluate_target_health = true

  }
}

resource "aws_route53_record" "top_level_www" {
  zone_id = "${data.aws_route53_zone.top_level.zone_id}"
  name    = "www.${data.aws_route53_zone.top_level.name}"
  type = "A"
  alias {
    name = "${aws_cloudfront_distribution.top_level.domain_name}"
    zone_id = "${aws_cloudfront_distribution.top_level.hosted_zone_id}"
    evaluate_target_health = true

  }
}
