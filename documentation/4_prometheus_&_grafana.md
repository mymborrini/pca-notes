# Prometheus & Grafana

There are two methodologies to create meaningful dashboards:

 - RED (Request Errors Duration)
 - USE (Utilization Saturation Errors)


Creating a dashboard that combines both methodology we provide a dashboard that monitor both user experience and system performance

Is a good idea to first create a query in prometheus using promql and then moving to the grafana dashboard.


To have the lf-app for this example do the following:

    git clone --depth=1 https://github.com/lftraining/LFS241.git
    mv LFS241 lf-app