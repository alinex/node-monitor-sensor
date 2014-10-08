Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 0.1.0 (2014-10-08)
-------------------------------------------------
- Fixed npmignore file.
- Small format fixes.
- Optimized dir analyzation to work quick in max. 30 sec for diskfree analysis.
- Initial disk space analyzation running.
- Initial disk space analyzation.
- Added top process analysis to load sensor.
- Added special format for load sensor.
- Changed timeouts on test run.
- Changed hint description for load.
- Fixed missing requires.
- Made default max responsetime for http longer.
- More output in tests.
- Fixed mocha test settings.
- Optimized layout in format().
- Reenable full test suite.
- Add analysis info to formatted output.
- Added format methods to return formated rersult.
- Added hints to sensor.
- Replace solors with chalk.
- Added cpu activity check.
- Internal restructure to get more functionality into base class.
- Added memory check.
- Added cpu load test sensor.
- Updated to new validator.
- Restructured sensors to automatically include them.
- Added validator selfchecks to mocha tests.
- Fixed bug in timeout of sockets.
- Updated to debug 2.0.0
- Added new sensor diskfree.
- Updated to use alinex-validator 0.2.
- Fixed calls to new make tool.
- Updated to alinex-make 0.3 for development.
- Remove EventEmitter support in sensor (done through controller).
- Return sensor in run() callback without error on normal fail.
- Removed direct dependency to alinex-validator.

Version 0.0.2 (2014-08-09)
-------------------------------------------------
- Added check methods for sensor configurations.
- Successful integration of alinex-validator.
- Changed check to use alinex-validator.
- Use validator in check method.
- Fixed config checks in ping.
- Merge branch 'master' of https://github.com/alinex/node-monitor-sensor
- Added Ping.check function.
- Extended documentation.
- Fixed bug in data collection for requests.
- Use the timeout settings in http requests.
- Added headers and body to data collection for http check.
- Add bodycheck and basic auth to http check.
- Added travis url.

Version 0.0.1 (2014-07-25)
-------------------------------------------------
- Added documentation for the sensor classes.
- Added code from the previous design concept in alinex-monitor.
- Initial commit

