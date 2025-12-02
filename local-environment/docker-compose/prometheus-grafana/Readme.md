# Prometheus & Grafana: Docker compose monitoring tutorial

We are going to expose a FastApi application that contains different kind of metrics
- Counter
- Gauge
- Histogram

After that we are going to scrap all of this metrics from prometheus and through grafana we are going to create a dashboard

To run docker compose with tags, use tags as profile, for example

    docker compose --profile obs up -d  