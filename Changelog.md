Version changes
=================================================

The following list gives a short overview about what is changed between
individual versions:

Version 0.1.2 (2014-11-19)
-------------------------------------------------
- Fixed option handling in internal spawn call.
- Finished net sensor.
- Added server list to net analysis.
- Added analysis for net sensor.
- Added network sensor.
- Updated documentation of all sensors.
- Updated status description.
- Test case fix.
- Small fixes and some new values in sensors.
- Added timeout option to time sensor.
- Added more options for ping.
- Added travis install command for additional packages.
- Removed success entry from values.
- Moved match function from http to base and finished http tests.
- Succeeded first body match tests.
- Reorganized sensors to work with new rules.
- Add support for logical operators.
- Added binary and interval support to check expressions.
- Add unit test for new base methods.
- Replaced hardcoded rules with defined ones.
- Small changes on documentation.
- Small fix in result display for http.
- Added time sensor.
- Added iostats sensor.
- Rename bodycheck config into body.
- Added more values to the http sensor.
- Limited parallel aptitude calls to number of system cores.
- Fixed bug in display of days in tables.
- Added support for percent measurement in diskfree.
- Add support for automatical  calculation of best interval unit.
- Fixed bug in diskfree with file analyzation (whitespace in names).
- Added upgrade command to hint.
- Added Low/mEdium/high/Security checks.
- Use localhost as default in socket sensor.

Version 0.1.1 (2014-10-16)
-------------------------------------------------
- Finished check for system upgrades.
- Fixed package.json version notation.
- Added value definition.
- Set up configuration values.
- Updated script for upgrade sensor.
- Initial system update sensor.

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

