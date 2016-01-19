# OpenSees

This directory contains an example [Agave App definition][1] for OpenSees.

## Contents

### `opensees-example-0.0.1.json`

This file is the App json description of the OpenSees app for Agave.

### `app/wrapper.sh`

The `app/` directory contains the `wrapper.sh` script for taking inputs and parameters
from the Agave Job and running OpenSees according to those inputs/parameters.

### `app/test/test.sh`

The `test.sh` script is used for testing `wrapper.sh` manually. Also included is an
example TCL input file, `Truss.tcl` from the [OpenSees Wiki Examples][2].

### `app/test/submit-job.json`

A minimal example of a Agave API Jobs document for running this app using the
[Agave Jobs API][3].

## Installation

Follow the [App Management Tutorial][1] for general instructions for installing apps into
Agave.

To install and run this app you must do the following:

1.  Install the OpenSees binary onto the `executionSystem` defined in the App json. The
    system listed in the provided json is `designsafe.exec.example`. You should update
    this value to the system where you installed OpenSees. (See the [Systems Tutorial][4]
    for more about systems.) You will also need to update `app/wrapper.sh` to with the
    correct path for `OPENSEES_BIN`.

2.  Upload `app/` to the storage system and path defined in `deploymentSystem` and
    `deploymentPath` as defined in the App's json.

3.  POST the App definition, `opensees-example-0.1.0.json`, to the Agave App API, e.g.:

    ```
    $ curl -H "Authorization: Bearer $TOKEN" -X POST https://agave.designsafe-ci.org/apps/v2/ -F "fileToUpload=@opensees-example-0.0.1.json"
    ```

4.  Run the app using the Agave Jobs API, e.g.:

    ```
    $ curl -H "Authorization: Bearer $TOKEN" -X POST https://agave.designsafe-ci.org/jobs/v2/ -F "fileToUpload=@app/test/submit-job.json"
    ```

[1]: http://agaveapi.co/documentation/tutorials/app-management-tutorial/
[2]: http://opensees.berkeley.edu/wiki/index.php/Basic_Truss_Example
[3]: http://agaveapi.co/documentation/tutorials/job-management-tutorial/
[4]: http://agaveapi.co/documentation/tutorials/system-management-tutorial/