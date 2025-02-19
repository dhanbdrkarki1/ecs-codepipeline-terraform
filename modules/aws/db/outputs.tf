output "db_instance_address" {
  value       = try(aws_db_instance.db[0].address, null)
  description = "Connect to the database at this endpoint"
}

output "db_instance_id" {
  value       = try(aws_db_instance.db[0].id, null)
  description = "The id of the database instance"
}

output "db_instance_port" {
  value       = try(aws_db_instance.db[0].port, null)
  description = "The port the database is listening on"
}