/* Data Sources */

data "aws_iam_policy_document" "backup_role_policy" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

/* Resources */

resource "aws_iam_role" "backup_role" {
  name_prefix        = "BackupRole"
  assume_role_policy = data.aws_iam_policy_document.backup_role_policy.json
}

resource "aws_iam_role_policy_attachment" "aws_backup_service_role_policy_for_backup_attach" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_vault" "webtrees" {
  name = "webtrees"
}

resource "aws_backup_plan" "daily_backup_plan" {
  name = "webtrees-daily-backup-plan"

  rule {
    rule_name         = "DailyBackups"
    target_vault_name = aws_backup_vault.webtrees.name
    schedule          = "cron(0 17 * * ? *)"
    start_window      = 480
    completion_window = 720

    lifecycle {
      delete_after = 35
    }
  }
}

resource "aws_backup_selection" "tag_based_backup_selection" {
  name         = "TagBasedBackupSelection"
  plan_id      = aws_backup_plan.daily_backup_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Name"
    value = aws_instance.webtrees.tags["Name"]
  }
}
