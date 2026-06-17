terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"
}

locals {
  name   = "aegis-demo"
  # Throwaway demo creds — ephemeral task, destroyed after capture.
  # In PROD these belong in AWS Secrets Manager, never the task definition.
  db_user    = "aegis"
  db_pass    = "aegis_demo_pw"
  db_name    = "aegis"
  jwt_secret = "demo-throwaway-secret-not-for-prod"
}

# ── Networking: reuse the default VPC's public subnets (demo only) ──
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ── KMS key for ECR and CloudWatch encryption ──
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "demo" {
  description             = "KMS key for ECS demo ECR and CloudWatch encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      }
    ]
  })
}

# ── ECR: private registry for your API image (Fargate can't pull local images) ──
resource "aws_ecr_repository" "aegis_api" {
  name                 = "${local.name}-api"
  image_tag_mutability = "IMMUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = aws_kms_key.demo.arn
  }
}

# ── CloudWatch logs: how you read WHY a container failed ──
resource "aws_cloudwatch_log_group" "aegis" {
  name              = "/ecs/${local.name}"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.demo.arn
}

# ── IAM: execution role (pull from ECR + write logs) ──
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${local.name}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Task role: the app needs NO AWS permissions here. Least privilege = empty.
resource "aws_iam_role" "ecs_task" {
  name               = "${local.name}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
}

# ── Security group: inbound 8000 from internet (demo only; accepted risk) ──
resource "aws_security_group" "aegis" {
  #checkov:skip=CKV_AWS_382:broad egress accepted for ephemeral demo environment
  name        = "${local.name}-sg"
  description = "Aegis demo - public API (ephemeral)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "FastAPI public access (demo)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound (ephemeral demo — destroyed after use)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "aegis" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ── One task, TWO containers (postgres + api). Redis cut — app doesn't use it. ──
resource "aws_ecs_task_definition" "aegis" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"  # 0.5 vCPU
  memory                   = "1024" # 1 GB — bump to 2048 if a container OOMs
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "postgres"
      image     = "public.ecr.aws/docker/library/postgres:16-alpine"
      essential = true
      environment = [
        { name = "POSTGRES_USER", value = local.db_user },
        { name = "POSTGRES_PASSWORD", value = local.db_pass },
        { name = "POSTGRES_DB", value = local.db_name }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "pg_isready -U ${local.db_user} -d ${local.db_name} || exit 1"]
        interval    = 10
        timeout     = 5
        retries     = 5
        startPeriod = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.aegis.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "postgres"
        }
      }
    },
    {
      name      = "api"
      image     = "${aws_ecr_repository.aegis_api.repository_url}:demo"
      essential = true
      portMappings = [
        { containerPort = 8000, protocol = "tcp" }
      ]
      # Postgres sidecar shares the network namespace → reachable at localhost.
      # +psycopg pins SQLAlchemy to psycopg v3 (matches database.py line 35).
      environment = [
        { name = "DATABASE_URL", value = "postgresql+psycopg://${local.db_user}:${local.db_pass}@localhost:5432/${local.db_name}" },
        { name = "SECRET_KEY", value = local.jwt_secret }
      ]
      # Don't start the API until Postgres reports healthy (avoids boot crash).
      dependsOn = [
        { containerName = "postgres", condition = "HEALTHY" }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://localhost:8000/health')\" || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 3
        startPeriod = 40
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.aegis.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "api"
        }
      }
    }
  ])
}

# ── Service: 1 task, public IP, NO load balancer (the cost we cut) ──
resource "aws_ecs_service" "aegis" {
  #checkov:skip=CKV_AWS_333:public IP required for direct access in this no-ALB demo config
  name            = local.name
  cluster         = aws_ecs_cluster.aegis.id
  task_definition = aws_ecs_task_definition.aegis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.aegis.id]
    assign_public_ip = true
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.aegis_api.repository_url
}
