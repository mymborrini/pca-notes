#!/usr/bin/env bash

function run() {
    curl -X POST --location "http://localhost:8000/items" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Test Item"
            }'

    curl -X GET --location "http://localhost:8000"
    curl -X GET --location "http://localhost:8000"
    curl -X GET --location "http://localhost:8000"
    curl -X GET --location "http://localhost:8000"
    curl -X GET --location "http://localhost:8000"


    curl -X GET --location "http://localhost:8000/items/1"
    curl -X GET --location "http://localhost:8000/items/2"
    curl -X GET --location "http://localhost:8000/items/3"
    curl -X GET --location "http://localhost:8000/items/4"
    curl -X GET --location "http://localhost:8000/items/5"
    curl -X GET --location "http://localhost:8000/items/6"

    curl -X PUT --location "http://localhost:8000/items/1" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Updated Item 1"
            }'

    curl -X PUT --location "http://localhost:8000/items/2" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Updated Item 2"
            }'

    curl -X PUT --location "http://localhost:8000/items/3" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Updated Item 3"
            }'

    curl -X PUT --location "http://localhost:8000/items/4" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Updated Item 4"
            }'


    curl -X PUT --location "http://localhost:8000/items/5" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "Updated Item 5"
            }'
}


for i in {1..100} ; do
    echo "Run $i iteration";
    run;
    sleep 5
done