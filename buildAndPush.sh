#!/bin/bash
docker pull php:7.4-apache-buster
docker build -t marcode79/bookstack:21.05.2-ee .
docker push marcode79/bookstack:21.05.2-ee
