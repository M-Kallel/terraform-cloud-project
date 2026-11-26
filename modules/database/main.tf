resource "aws_db_subnet_group" "db" {
  name       = var.prefix
  subnet_ids = var.db_ids
}
resource "aws_db_instance" "db" {
  identifier                  = "${var.prefix}-mysql"
  engine                      = "mysql"
  instance_class              = var.db_instance_class
  allocated_storage           = 20
  storage_type                = "gp3"
  username                    = "cloudadmin"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [var.db_sg]
  publicly_accessible         = false
  storage_encrypted           = true
  multi_az                    = var.production
  backup_retention_period     = var.production ? 7 : 1
  deletion_protection         = var.production
  skip_final_snapshot         = !var.production
  final_snapshot_identifier   = var.production ? "${var.prefix}-final" : null
}
