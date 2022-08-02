resource "aws_dynamodb_table" "watch_inventory" {
  name           = "WatchInventory"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "ModelNumber"
  range_key      = "Colorway"

  attribute {
    name = "ModelNumber"
    type = "S"
  }

  //will be the bezel and the dial combined
  attribute {
    name = "Colorway"
    type = "S"
  }

  # attribute {
  #   name = "Brand"
  #   type = "S"
  # }

  # attribute {
  #   name = "Model"
  #   type = "S"
  # }

  # attribute {
  #   name = "Size"
  #   type = "S"
  # }
  # attribute {
  #   name = "Bracelet"
  #   type = "S"
  # }
  # attribute {
  #   name = "Dial"
  #   type = "S"
  # }
  # attribute {
  #   name = "Bezel"
  #   type = "S"
  # }
  # attribute {
  #   name = "Images"
  #   type = "L"
  # }

  # status

  # ttl {
  #   attribute_name = "TimeToExist"
  #   enabled        = false
  # }
}
