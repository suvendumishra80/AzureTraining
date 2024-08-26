resource "google_logging_metric" "instance_stopped_metric" {
  name        = "Instance-Stopped-Metric"
  description = "Instance Stopped Metric"
  filter      = "resource.type=\"gce_instance\" AND protoPayload.methodName=\"v1.compute.instances.stop\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_logging_metric" "instance_delete_metric" {
  name        = "Instance-Delete-Metric"
  description = "Instance Delete Metric"
  filter      = "resource.type=\"gce_instance\" AND protoPayload.methodName=\"v1.compute.instances.delete\""

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "instance_stopped_alert" {
  display_name = "Instance Stopped Alert"
  combiner     = "OR"
  enabled      = true
  

  conditions {
    display_name = "Instance Stopped"
    condition_threshold {
      
      filter           = "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.instance_stopped_metric.name}\""
      duration         = "0s"
      comparison       = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_COUNT"
        group_by_fields = ["metadata.system_labels.name"]
      }
      threshold_value  = 0.99  # Set the threshold value as per your requirement (e.g., 0.99 for 99% availability)
      trigger {
        count = 1
      }
    }
  }
  alert_strategy {
    auto_close= "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}

resource "google_monitoring_alert_policy" "instance_delete_alert" {
  display_name = "Instance Deleted Alert"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Instance Deleted"
    condition_threshold {
  
      filter           = "resource.type = \"gce_instance\" AND metric.type = \"logging.googleapis.com/user/${google_logging_metric.instance_delete_metric.name}\""
      duration         = "0s"
      comparison       = "COMPARISON_GT"
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_COUNT"
        cross_series_reducer = "REDUCE_COUNT"
        group_by_fields = ["metadata.system_labels.name"]
      }
      threshold_value  = 0.99  # Set the threshold value as per your requirement (e.g., 0.99 for 99% availability)
      trigger {
        count = 1
      }
    }
  }
  alert_strategy {
    auto_close= "1800s"
  }

  notification_channels = [google_monitoring_notification_channel.email_alerts.id]
}
resource "google_monitoring_notification_channel" "email_alerts" {
  display_name = "Email Alerts"
  type         = "email"
  labels = {
    email_address = "suvendu-kumar.mishra@lloydsbanking.com"  # Replace with your email address
  }
}
