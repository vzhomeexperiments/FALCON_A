# FALCON_A

Designed to work best with Decision Support System developed inside Lazy Trading Project

https://vladdsm.github.io/myblog_attempt/topics/lazy%20trading/

# Introduction

Model-based trading robot. Main features are listed below:

* Does not require optimization of parameters
* Learns from past trading experience
* Able to read Market Type
* Able to log Market Type status to the file
* Works with Reinforcement Learning Policy to identify which market type is more suitable to trade in

# Reference

Functionality of this EA will be explained in the Udemy course [Developing Self Learning Trading Robot](https://www.udemy.com/self-learning-trading-robot/?couponCode=LAZYTRADE7-10)

This repository is to keep existing EA working on 28 currencies and forcedly trained with kNN methods used code from [here](https://www.mql5.com/en/code/8645)

Original code: Stat_Euclidean_Metric.mq4

# How this will work?

> - Go to Tester and set up parameter Base = True. 
> - Select large amount of time period and start trades simulation.
> - Then change parameter Base = False. 
> - Run simulation again

Finally in order to use in trading mode move files from /tester folder to the /Files folder

# Disclaimer

Use on your own risk: past performance is no guarantee of the future results!
