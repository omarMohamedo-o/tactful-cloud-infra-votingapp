variable "kube_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "voting-app-dev"
}

variable "namespace" {
  description = "Kubernetes namespace for the voting app"
  type        = string
  default     = "voting-app"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "PostgreSQL password"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "postgres"
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  default     = "redis123"
  sensitive   = true
}

variable "vote_replicas" {
  description = "Number of vote app replicas"
  type        = number
  default     = 2
}

variable "result_replicas" {
  description = "Number of result app replicas"
  type        = number
  default     = 2
}

variable "worker_replicas" {
  description = "Number of worker replicas"
  type        = number
  default     = 1
}

variable "vote_image" {
  description = "Vote application image"
  type        = string
  default     = "tactful-votingapp-cloud-infra-vote:latest"
}

variable "result_image" {
  description = "Result application image"
  type        = string
  default     = "tactful-votingapp-cloud-infra-result:latest"
}

variable "worker_image" {
  description = "Worker application image"
  type        = string
  default     = "tactful-votingapp-cloud-infra-worker:latest"
}
