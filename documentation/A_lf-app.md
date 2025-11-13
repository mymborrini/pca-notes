# Lf-App


The lf-app is necessary to make experience with prometheus.

## Download lf-app

    git clone --depth=1 https://github.com/lftraining/LFS241.git
    mv LFS241 lf-app

## Instrumenting code

Go into lf-app/instrumentation-excercise/go and change the Dockerfile replacing:

    3rd line: COPY ./main-instrumented.go .
    8th line: CMD ["go", "run", "main-instrumented.go"]

Then go into lf-app/instrumentation-excercise/python and change the Dockerfile replacing:

    4th line: COPY ./server-instrumented.py .
    6th line: CMD ["python","server-instrumented.py"]

