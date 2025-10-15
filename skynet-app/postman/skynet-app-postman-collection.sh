#!/usr/bin/env bash

function create_objects() {
  for i in {1..45} ; do
      curl -X POST --location "http://localhost:8000/items" \
          -H "Content-Type: application/json" \
          -d '{
                "name": "Created Item"
              }'
  done

}

function run() {

    for i in {1..5} ; do
        curl -X GET --location "http://localhost:8000"
    done


    for i in {1..6} ; do
       curl -X DELETE --location "http://localhost:8000/items/$i"
    done


    for i in {1..60} ; do
        curl -X GET --location "http://localhost:8000/items/$i"
    done

    for i in {15..45} ; do
         curl -X PUT --location "http://localhost:8000/items/$i" \
                -H "Content-Type: application/json" \
                -d "{\"name\": \"Updated Item $i\"}"
    done


}


for i in {1..100} ; do
    echo ""
    echo "Run $i iteration";
    run;
    echo ""
    sleep 5
done