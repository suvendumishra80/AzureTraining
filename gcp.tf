provider "google" {
    credentials = "${file("mygcpservicekey.json")}"
    project = var.project_id
    region  = var.region
    zone    = var.zone
}

# Creating Bucket for our cloud function to use
resource "google_storage_bucket" "bucket" {
  name = "${var.bucket_name}-conversion"
  location = var.region
}


# Cloud function for Yaml to Json Parsing 
resource "google_cloudfunctions_function" "yaml-to-json" {
  name        = "yaml-to-json-parser"
  runtime     = "python38"
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = "yaml-to-json-parser.zip"
  entry_point = "convert_yaml_to_json_gcs"
  trigger_http = var.trigger_http

  # Adding bucket in environment variable to use bucket in cloud function
  environment_variables = {
    BUCKET_NAME = google_storage_bucket.bucket.name
  }

  timeout = var.timeout

  available_memory_mb = var.available_memory_mb

  # Use Python code and it's dependencies from requirements.txt file's zip archive upload on bucket
  depends_on = [
    google_storage_bucket_object.zip
  ]
}


# Binding storage admin role for the cloudfunction SA to be able to get,upload the files 
resource "google_storage_bucket_iam_binding" "Bucketiam_binding" {
  bucket = google_storage_bucket.bucket.name
  role   = "roles/storage.objectAdmin"

  members = [
    # "serviceAccount:var.service_account",
    "serviceAccount:${google_cloudfunctions_function.yaml-to-json.service_account_email}"
  ]
}

# IAM entry to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  cloud_function = google_cloudfunctions_function.yaml-to-json.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

# Creating a zip file to have the code and it's requirments. to get use in cloud function source
data "archive_file" "my_zip_file" {
  type        = "zip"
  source_dir = "function_code"
  output_path = "yaml-to-json-parser.zip"
}


# uploading the created archive zip on the GCS bucket
resource "google_storage_bucket_object" "zip" {
  name   = "yaml-to-json-parser.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${data.archive_file.my_zip_file.output_path}"
}
