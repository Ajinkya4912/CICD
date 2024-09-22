# Provider for AWS
provider "aws" {
  region = "ap-south-1" # Change this to your preferred region
}
# Step 1: Create an ECR Repository
resource "aws_ecr_repository" "app" {
  name = "my-app-repo" # The name of the ECR repository
}
# Step 2: Create an ECS Cluster
resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"
}
# Step 3: IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Attach necessary policies for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
# Step 4: Create an ECS Task Definition
resource "aws_ecs_task_definition" "app_task" {
  family = "app-task"
  container_definitions = jsonencode([{
    name      = "my-app-container"
    image     = "${aws_ecr_repository.app.repository_url}:latest"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
}
# Step 5: Create an ECS Service
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "EC2"
}
