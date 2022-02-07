reflow-nodered
==============

### About

This repository contains a simple REST API interface implemented in Node-red (running locally in Docker) to the GraphQL interface offered by Bonfire, 
and a bash script that makes use of this interface to enter data relative to the following flow:

An isolation gown is created by a company that also takes care of the cleaning, it is transported to the hospital, 
it is used to perform surgery and therefore becomes dirty, it is transported back to the owner company, and it is washed there.

The cycle potentially repeats endlessy (or for a number of times)

### Installation

You need to have docker installed on your machine, since Node-red will run inside Docker.

Clone the repository, install the packages with `npm install` and you should be set to go.

### Running

Start Docker, when it is up run the scritp `start.sh`
Connect to http://127.0.0.1:1880/ to see your Node-red instance.

To run the script, you need to know which Bonfire instance to target; currently the script is aware of:
- demo : 'https://reflow-demo.dyne.org/api/explore'
- shared : 'http://135.181.35.156:4000/api/explore'

If you are running your own instance, edit the script `curl.sh` in the case swith under `# read the endpoint`

For the chosen instance you need to have the credentials of two users, and set them in `.credentials.sh` 
(an example of the fields and format of the file is in `.credentials.example.sh`)

Then you can run the script as following:

`./curl.sh <name of instance you set in script> N N` where the first N is for Not perform init and the second is for do Not print debug information.

Initialisation is required when you need to create units of measures and locations of agents, and once done these data is stored on file 
(named as `init_<instance's name>.json`, for ex. `init_reflow-demo.dyne.org.json`) so not to have to create it again.


