# Variable for the database administrator login
variable "db_admin_login" {
  description = "Database administrator login"
}

# Variable for the database administrator password
variable "db_admin_password" {
  description = "Database administrator password"
  sensitive = true  # Marking the variable as sensitive
}

# Variable for the database name
variable "db_name" {
  description = "Database name"
}
