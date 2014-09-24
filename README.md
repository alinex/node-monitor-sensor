Package: alinex-monitor-sensor
=================================================

[![Build Status] (https://travis-ci.org/alinex/node-monitor-sensor.svg?branch=master)](https://travis-ci.org/alinex/node-monitor-sensor)
[![Coverage Status] (https://coveralls.io/repos/alinex/node-monitor-sensor/badge.png?branch=master)](https://coveralls.io/r/alinex/node-monitor-sensor?branch=master)
[![Dependency Status] (https://gemnasium.com/alinex/node-monitor-sensor.png)](https://gemnasium.com/alinex/node-monitor-sensor)

This module is part of the [Monitoring](http://alinex.github.io/node-monitor)
modules and applications but can be used as standalone module in other projects,
too.

- it has multiple sensors
- runs completely asynchronous
- analyses the process
- collects all the data
- supports verbose mode and debugging

It is one of the modules of the [Alinex Universe](http://alinex.github.io/node-alinex)
following the code standards defined there.


Install
-------------------------------------------------

The easiest way is to let npm add the module directly:

    > npm install alinex-monitor-sensor --save

[![NPM](https://nodei.co/npm/alinex-monitor-sensor.png?downloads=true&stars=true)](https://nodei.co/npm/alinex-monitor-sensor/)


Usage
-------------------------------------------------

To use one of the sensors you have to load the sensors collection:

    var sensor = require('alinex-monitor-sensor');

Or you may only load one specific sensor class:

    var Ping = require('alinex-monitor-sensor/lib/ping');

In the further documentation i will show usage with the sensor collection.

### Sensor run

To use any sensor you have to instantiate and configure it:

    var ping = new sensor.Ping({
      ip: '193.99.144.80'
    });

You may also give a [alinex-config](http://alinex.github.io/node-config) object
here.

Now you can start it using a callback method:

    ping.run(function(err, sensor) {
      // do something with result in ping object
      console.log(sensor);
    });

Or alternatively you may use an event based call:

    ping.run();
    ping.on 'end', function() {
      // do something with result in ping object
      console.log(ping);
    });

The `ping` object looks like:

    { config: { verbose: false, timeout: 1, ip: '137.168.111.222' },
      result:
      { date: Tue Jul 22 2014 14:08:34 GMT+0200 (CEST),
        status: 'fail',
        data: '1 packets transmitted, 0 received, 100% packet loss, time 0ms',
        message: 'Ping exited with code 1'
      }
    }


Status
-------------------------------------------------
The sensors uses the following status:

__running__ if the sensor is already analyzing, you have to wait

__ok__ if everything is perfect, there nothing have to be done

__warn__ if the sensor reached the warning level, know you have to keep an eye on it

__fail__ if the sensor failed and there is a problem


API
-------------------------------------------------

### Sensor classes

- [Load](src/type/load.coffee) - cpu load check
- [Diskfree](src/type/diskfree.coffee) - free disk space
- [Ping](src/type/ping.coffee) - network ping test
- [Socket](src/type/socket.coffee) - test port connectivity
- [Http](src/type/http.coffee) - try requesting an url

#### Methods

- `run(cb)` - start a new analyzation with optional callback

#### Events

- `error` - then the sensor could not work properly
- `start` - sensor has started
- `end` - sensor ended analysis
- `ok` - no problems found
- `warn` - warning means high load or critical state
- `fail` - not working correctly

#### Static properties

- `meta` - some meta data for this test type
  - `name` - title of the test
  - `description` - short description what will be checked
  - `category` - to group similiar tests together
  - `level` - gives a hint if it is a low level or higher level test
- `values` - meta information for the measurement values
- `config` - the default configuration
  (each entry starting with underscore gives the help text for that value)
- `check` - check function for the configuration values (alinex-config
  style)

#### Properties

- `config` - configuration (given combined with defaults)
- `result` - the results:
  - `date` - start date of last or current run
  - `status` - status of the last or current run (ok, warn, fail)
  - `value` - map of measured values
  - `data` - complete data from the last or current run
  - `message` - error message of the last or current run


License
-------------------------------------------------

Copyright 2014 Alexander Schilling

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

>  <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
