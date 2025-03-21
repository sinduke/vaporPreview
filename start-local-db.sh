#!/bin/bash
docker build -f Dockerfile.db -t postgres .
docker run --name postgres -p 5432:5432 -d postgres