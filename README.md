# Elastic Weather

<img src="images/weather.png" align="right" height="180" style="margin-top: -25px;" />

Many invents are influenced by weather.  Sometimes we need to plot weather behavior alongside our business or IT data so that we can spot a correlation.  The [OpenWeather](https://openweathermap.org) project provides 40 years of hourly weather conditions for a nominal feel.

Purchase 40 years of hourly weather data from OpenWeather:

[https://home.openweathermap.org/marketplace](https://home.openweathermap.org/marketplace)

The following script will load a JSON file from their archive into Elasticsearch.

```
$ ./load.rb 

usage: ./load.rb [options]
    -n, --name     Name of index
    -r, --reindex  Reindex (delete, create, index)
    -c, --create   Create the index
    -d, --delete   Delete the index
    -i, --import   Import the index
    -s, --status   Get cluster status
    
```

Before importing, create a `.env` file to set your Elastic cluster information:

```
$ vi .env
```

Source the `.env` in your shell:

```
$ . .env
```

Then run the import:

```
$ ./import.rb -n weather -r
Deleting index for weather ...
Creating index for weather ...
Importing weather in batches of 100 ...
[##########################################] [3700/3700] [100.00%] [10:44] [00:00] [   5.74/s]
Getting cluster status ... green
Took 0.1107 ms

```