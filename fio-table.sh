#!/bin/bash

        for bs in 4k 8k 16k 32k 64k 128k 256k 512k 1024k; do
                RESULTS=$(
                        fio \
                                --randrepeat=1 \
                                --ioengine=libaio \
                                --direct=0 \
                                --gtod_reduce=1 \
                                --name=test \
                                --filename=test \
                                --iodepth=64 \
                                --size=4G \
                                --readwrite=randrw \
                                --rwmixread=60 \
                                --loops=10 \
                                --bs=${bs} \
                                --output-format=json;
                );
                printf "${recordsize}, ";
                printf "${bs}, ";
                echo $RESULTS | jq '.jobs[] | .read.bw_mean' | tr -d '\n';
                printf ", ";
                echo $RESULTS | jq '.jobs[] | .read.iops_mean' | tr -d '\n';
                printf ", ";
                echo $RESULTS | jq '.jobs[] | .write.bw_mean' | tr -d '\n';
                printf ", ";
                echo $RESULTS | jq '.jobs[] | .write.iops_mean' | tr -d '\n';
                echo;
                sleep 20;
        done;
