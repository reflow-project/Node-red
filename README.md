reflow-nodered
==============

### About

This repository contains a simple REST API interface implemented in Node-red (running locally in Docker) to the GraphQL interface offered by Bonfire, 
and a bash script that makes use of this interface to enter data relative to the following flow:

An isolation gown is created by a company that also takes care of the cleaning --> it is transported to the hospital
--> it is used to perform surgery and therefore becomes dirty --> it is transported back to the owner company --> it is washed there.

The cycle potentially repeats endlessy (or for a number of times), in the script is only executed once.

The goal of the script is to generate a Material Passport for the Isolation Gown resource, and that is what the script outputs at the end, and it is logged in the file `MP-<name of Bonfire machine>.log`.

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

### Screenshots
The following screenshot shows the tab in Node-red where the HTTP endpoints are defined that encapsulate the GraphQL calls to Bonfire. These endpoints are called by the script `curl.sh` to enter the simple flow described above in Bonfire.

![Node-red tab with endpoints](/screenshots/endpoints.png?raw=true "Node-red tab with endpoints")

The following screenshot shows a fragment of the code used to process the form data received by the Event endpoint to trasform it in a GraphQL request.

![Event endpoint processing code](/screenshots/codenode.png?raw=true "Event endpoint processing code")

As mentioned above, the output generate by running the script is in `MP-<name of Bonfire machine>.log`.
