#Create Stoarge Bucket for Website content

resource "google_storage_bucket" "bky-bucket-website" {
  name     = "bky-website-bucket-test-01"
  location = "US"
}

#Make object publicly accesible

resource "google_storage_object_access_control" "BKY-Public-Access" {
  bucket = google_storage_bucket.bky-bucket-website.name
  object = google_storage_bucket_object.BKY-Source-files.name
  role   = "READER"
  entity = "allUsers"

}

#Upload website sources files into Remote Bucket

resource "google_storage_bucket_object" "BKY-Source-files" {
  name   = "index.html"
  source = "/Users/gokhany/Documents/CSG-Codes/GCP_Terraform_Docker/website-source/index.html"
  bucket = google_storage_bucket.bky-bucket-website.name

}

#Reserve Ststis Public IP

resource "google_compute_global_address" "website_ip" {
  name = "website-lb-ip"

} #Get managed domain zone

data "google_dns_managed_zone" "bky-zone" {
  name = "bky-test-domain"
}

#Add IP into DNS zone
resource "google_dns_record_set" "website-ip-add" {
  name         = "website.${data.google_dns_managed_zone.bky-zone.dns_name}"
  type         = "A"
  ttl          = "300"
  managed_zone = data.google_dns_managed_zone.bky-zone.name
  rrdatas      = [google_compute_global_address.website_ip.address]
}

#Add bucket as CDN backend

resource "google_compute_backend_bucket" "website-backend" {
  name        = "website-bucket-be"
  bucket_name = google_storage_bucket.bky-bucket-website.name
  description = "contains files for website"
  enable_cdn  = true
}

#Create URL Map
resource "google_compute_url_map" "bky-url-map" {
  name            = "bky-website-map"
  default_service = google_compute_backend_bucket.website-backend.self_link
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.website-backend.self_link
  }
}

#GCP HTTP roxy

resource "google_compute_target_http_proxy" "bky-http-proxy" {
  name    = "website-proxy"
  url_map = google_compute_url_map.bky-url-map.self_link

}

#GCP Forwarding rule

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "bky-ford-rule"
  load_balancing_scheme = "EXTERNAL"
  ip_address            = google_compute_global_address.website_ip.address
  ip_protocol           = "TCP"
  port_range            = "80"
  target = google_compute_target_http_proxy.bky-http-proxy.self_link
}