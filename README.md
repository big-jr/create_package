# create_package.sh

A bash script to create Lambda and Lambda Layer deployment packages for Lambdas written in Python.

## Summary

This bash script creates Lambda and Lambda Layer deployment packages in the form of ZIP files, that are ready to be uploaded to AWS.

Lambda Layers may contain multiple Python run-times. All packages for all run-times will be included.

The packages are build using Docker and AWS Linux to stop import and symbol errors from occurring - see the [original article](https://www.softwarepragmatism.com/creating-an-aws-lambda-with-dependencies-using-python-part-2-fixing-import-and-undefined-symbol-errors) for more details.

## Examples

`create_package.sh ./mylambda -o mylambda_deploy.zip -p 3.7`

Takes the Python code in the `./mylambda` directory, uses it to create a Lambda deployment package running against Python 3.7 in `mylambda_deploy.zip`.

`create_package.sh ./mylayer -o mylayer_deploy.zip -v 3.7,3.8`

Takes the `requirements.txt` file in the `./mylayer` directory, and uses it to create a Lambda Layer deployment package containing compatible code for Python 3.7 and Python 3.8.

## Notes

This script originates in the [Software Pragmatism](https://www.softwarepragmatism.com/) article [Creating An AWS Lambda With Dependencies Using Python, Part 2 - Fixing Import and Undefined Symbol Errors](https://www.softwarepragmatism.com/creating-an-aws-lambda-with-dependencies-using-python-part-2-fixing-import-and-undefined-symbol-errors).
