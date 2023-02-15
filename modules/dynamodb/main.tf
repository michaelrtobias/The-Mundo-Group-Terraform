resource "aws_dynamodb_table" "watch_inventory" {
  name           = "watchInventory"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "brand"
  range_key      = "colorway"

  //will be the bezel and the dial combined
  attribute {
    name = "colorway"
    type = "S"
  }
  attribute {
    name = "brand"
    type = "S"
  }


  # status

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }
}
