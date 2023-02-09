<!--
SPDX-License-Identifier: AGPL-3.0-or-later
Copyright (C) 2021-2023 Dyne.org foundation <foundation@dyne.org>.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
-->

Node-RED for Interfacer
==============

### About

This repository contains a simple REST API interface implemented in Node-red (running locally in Docker) to the GraphQL interface offered by the Interfacer back-enc, and a bash script that makes use of this interface to enter data relative to the following flow:

An isolation gown is created by a company that also takes care of the cleaning --> it is transported to the hospital
--> it is used to perform surgery and therefore becomes dirty --> it is transported back to the owner company --> it is washed there.

The cycle potentially repeats endlessy (or for a number of times), in the script is only executed once.

The goal of the script is to generate a Material Passport for the Isolation Gown resource, and that is what the script outputs at the end, and it is logged in the file `MP-<name of Interfacer machine>.log`.

### Installation

You need to have docker installed on your machine, since Node-red will run inside Docker.

Clone the repository, install the packages with `npm install` and you should be set to go.

### Running

Start Docker, when it is up run the scritp `startNodeRed.sh`
Connect to http://127.0.0.1:1880/ to see your Node-red instance.

To run the script, you need to know which Interface instance to target; currently the script is aware of:
- testing : 'http://65.109.11.42:9000/api'

If you are running your own instance, edit the script `doFlow.sh` in the case switch under `# read the endpoint`

For the chosen instance you need to have create the credentials (keypair) of two users, have a look at the files `.creds_hosp_example.json` and `.creds_clean_example.json`

Then you can run the script as following:

`./doFlow.sh <name of instance you set in script> N N` where the first N is for Not perform init and the second is for do Not print debug information.

Initialisation is required when you need to create units of measures and locations of agents, and once done these data is stored on file 
(named as `init_<instance's name>.json`, for ex. `init_<IP address>.json`) so not to have to create it again.

### Screenshots
(Please note: the screenshots are not regularly updated, they are used to give an idea of the system).

The following screenshot shows the tab in Node-red where the HTTP endpoints are defined that encapsulate the GraphQL calls to the Interface back-end. These endpoints are called by the script `doFlow.sh` to enter the simple flow described above in the back-end.

![Node-red tab with endpoints](/screenshots/endpoints.png?raw=true "Node-red tab with endpoints")

The following screenshot shows a fragment of the code used to process the form data received by the Event endpoint to trasform it in a GraphQL request.

![Event endpoint processing code](/screenshots/codenode.png?raw=true "Event endpoint processing code")

As mentioned above, the output generate by running the script is in `MP-<name of Interfacer machine>.log`.
