# What is the purpuse of this project 


the genesis of this project come from this youtube video (https://www.youtube.com/watch?v=yxnKeTL2I6E) where a tech journalist explain how speed test working and at the same time i have some wi-fi problem. So i use my program and data knowledge in order to track the speed quality of the network where i'am connected. I choose the speedtest from cloudflare for this project and ipinfo.io in order to retreive some information about the network (localisation ...). I choose to use another open source project that permit to run with a one line command a cloudflare speedtest you can check this projet with this link (https://github.com/KNawm/speed-cloudflare-cli)


# Project Architecture




I choose to write this project in bash using postegreSQL with Homebrew in order to not use any packages and language for facilitate the implementation of this architecture. As you can see in this schema 


![speedtest_viz drawio](https://github.com/Francois-lenne/speedtest_viz/assets/114836746/c2c1f02a-0b29-49bd-858e-50e65d3f8561)


## The Project Stack

[![My Skills](https://skills.thijs.gg/icons?i=bash,apple,postgres)](https://skills.thijs.gg)


## Conceptual Data Model (CDM)




# How can you implement this project on your mac 

First, you need to open your terminal and enter this commands

```
git clone https://github.com/Francois-lenne/speedtest_viz/tree/master
```

Make the script executable in order to implement the architecture 

```
chmod +x myscript.sh
```

then you can run this script automaticly with cron if you want it


```
./myscript.sh
```


