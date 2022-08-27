data "archive_file" "hello" {
  type = "zip"

  source_dir  = "${path.module}/hello"
  output_path = "${path.module}/hello.zip"
}