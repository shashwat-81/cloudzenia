variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_ids" {
  description = "EC2 instance IDs from Challenge 2 (must have SSM + CloudWatch IAM profile)"
  type        = list(string)
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group for NGINX access logs"
  type        = string
  default     = "/ec2/nginx/access"
}

resource "aws_cloudwatch_log_group" "nginx_access" {
  name              = var.cloudwatch_log_group_name
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-nginx-access-logs"
  }
}

resource "aws_ssm_document" "cloudwatch_agent" {
  name            = "${var.project_name}-install-cloudwatch-agent"
  document_type   = "Command"
  document_format = "YAML"

  content = <<-DOC
    schemaVersion: "2.2"
    description: Install CloudWatch agent for RAM metrics and NGINX access logs
    parameters:
      LogGroupName:
        type: String
        default: "${var.cloudwatch_log_group_name}"
    mainSteps:
      - action: aws:runShellScript
        name: configureCloudWatchAgent
        inputs:
          runCommand:
            - |
              set -euo pipefail
              export DEBIAN_FRONTEND=noninteractive
              apt-get update -y
              apt-get install -y amazon-cloudwatch-agent

              cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWCFG'
              {
                "metrics": {
                  "append_dimensions": {
                    "InstanceId": "$${aws:InstanceId}"
                  },
                  "metrics_collected": {
                    "mem": {
                      "measurement": ["mem_used_percent"],
                      "metrics_collection_interval": 60
                    }
                  }
                },
                "logs": {
                  "logs_collected": {
                    "files": {
                      "collect_list": [
                        {
                          "file_path": "/var/log/nginx/access.log",
                          "log_group_name": "{{ LogGroupName }}",
                          "log_stream_name": "{instance_id}/nginx-access",
                          "timezone": "UTC"
                        }
                      ]
                    }
                  }
                }
              }
              CWCFG

              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a stop || true
              /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
                -a fetch-config -m ec2 \
                -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
  DOC

  tags = {
    Name = "${var.project_name}-cloudwatch-agent-ssm"
  }
}

resource "aws_ssm_association" "cloudwatch_agent" {
  count = length(var.instance_ids)

  name = aws_ssm_document.cloudwatch_agent.name

  targets {
    key    = "InstanceIds"
    values = [var.instance_ids[count.index]]
  }

  parameters = {
    LogGroupName = var.cloudwatch_log_group_name
  }

  depends_on = [aws_cloudwatch_log_group.nginx_access]
}

output "nginx_access_log_group" {
  value = aws_cloudwatch_log_group.nginx_access.name
}

output "ssm_document_name" {
  value = aws_ssm_document.cloudwatch_agent.name
}
