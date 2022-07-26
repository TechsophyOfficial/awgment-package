#!/bin/sh
set -xe


# create registry container unless it already exists
export reg_name='kind-registry'
export reg_port='5001'
export postgres_host=192.168.1.46
export postgres_port=your_postgres_port
export mongo_host=192.168.1.46
export mongo_port=your_mongo_port
export docker_user=techsophy
export docker_password=web@987

