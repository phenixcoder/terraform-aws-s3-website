data "aws_iam_policy_document" "website_bucket" {
  statement {
    sid    = "PublicReadForGetBucketObjects"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      "arn:aws:s3:::${local.domain_name}-website/*"
    ]
  }
}