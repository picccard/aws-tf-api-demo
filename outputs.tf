output "base_url" {
  description = "Base URL for API Gateway stage."

  value = aws_apigatewayv2_stage.lambda.invoke_url
}

output "hello_route" {
  description = "/hello route"

  value = "${aws_apigatewayv2_stage.lambda.invoke_url}${split(" ", aws_apigatewayv2_route.hello.route_key)[1]}"
}