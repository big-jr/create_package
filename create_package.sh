#!/bin/bash

TEMP_PACKAGE_NAME="temp_package.zip"


function usage()
{
  echo "Usage: cmd SOURCE [-o FILENAME] [-p VERSION] | [-v VERSIONS]"
  echo "     "
  echo "  SOURCE The directory containing the source code for the package"
  echo "     "
  echo "  -o, --output           The path and name of the package ZIP file"
  echo "     e.g.:"
  echo "         -o mypackage.zip"
  echo "     "
  echo "  -p, --package_version  Create a Lambda deployment package for Python version VERSION"
  echo "     e.g.:"
  echo "         -p 3.8"
  echo "     "
  echo "  -v, --layer_versions   Create a Lambda Layer package including specified depedencies"
  echo "     for Python versions specified in comma-separated list, e.g.:"
  echo "         -v 3.7,3.8"
}


function build_layer_package()
{
  # Build a Lambda Layer package
  # Arguments: $1: Source Directory
  #            $2: Output path
  #            $3: Lambda Layer versions
  echo "Building a layer package with runtimes: ${3}"
  versions=${3};
  for i in $(echo ${versions} | sed "s/,/ /g")
  do
    echo "Python version ${i}"
    mkdir -p "python/lib/python${i}"
    docker run -v "$PWD":/var/task "lambci/lambda:build-python${i}" /bin/sh -c "pip install --upgrade -r ${1}/requirements.txt -t ${1}/python/lib/python${i}/site-packages/; exit"
  done

  # Ensure the ZIP file contains the correct paths
  cd "${1}"
  zip -r ${TEMP_PACKAGE_NAME} ./python > /dev/null
  rm -Rf ./python
  cd "$OLDPWD"
  mv "${1}/${TEMP_PACKAGE_NAME}" "${2}"
}


function build_lambda_package()
{
  # Build a Lambda package
  # Arguments: $1: Source Directory
  #            $2: Output path
  #            $3: Lambda runtime version
  echo "Building a lambda package with runtime: ${3}"
  version=${3};
  docker run -v "$PWD":/var/task "lambci/lambda:build-python${version}" /bin/sh -c "pip install --upgrade -r ${1}/requirements.txt -t ${1}/libs; exit"

  # Ensure the ZIP file contains the correct paths
  cd "${1}"

  zip -r ${TEMP_PACKAGE_NAME} ./libs > /dev/null
  zip -r ${TEMP_PACKAGE_NAME} ./*.py > /dev/null
  zip -r ${TEMP_PACKAGE_NAME} ./requirements.txt > /dev/null
  rm -Rf ./libs
  cd "$OLDPWD"
  mv "${1}/${TEMP_PACKAGE_NAME}" "${2}"
}

# If the first argument is non-existent or requests help, show it and exit
if [[ (-z $1 || "$1" == "-h" || "$1" == "--help") ]]; then
  usage
  exit
fi

# Otherwise, first argument should be the source directory
source_directory="$1"
shift

layer_versions=
package_runtime=
output_file="package.zip"


while [ "$1" != "" ]; do
    case $1 in
        -v | --layer_versions )
            shift
            layer_versions="$1"
            echo "Package runtime: ${layer_versions}"
            if [ -z "${layer_versions}" ]; then
              # layer_versions argument length is 0
              echo "Invalid option: v/layer_versions requires an argument"
              exit 1
            elif [ -n "${package_runtime}" ]; then
              # package_runtime length > 0
              echo "Invalid option: v/layer_versions cannot be specified as well as p/package_runtime"
              echo "Layer versions: ${package_runtime}"
              exit 1              
            fi
          ;;

        -p | --package_runtime )
            shift
            package_runtime="$1"
            echo "Package runtime: ${package_runtime}"
            if [ -z "${package_runtime}" ]; then
              # package_runtime argument length is 0
              echo "Invalid option: p/package_runtime requires an argument"
              exit 1
            elif [ -n "${layer_versions}" ]; then
              # layer_versions length > 0
              echo "Invalid option: p/package_runtime cannot be specified as well as v/layer_versions"
              echo "Layer versions: ${layer_versions}"
              exit 1              
            fi
          ;;

        -o | --output )
            shift
            output_file="$1"
          ;;

        -h | --help )
            usage
            exit
          ;;

        * )
            usage
            exit 1

    esac
    shift
done

# Actually do the building
if [ -n "${layer_versions}" ]; then
  build_layer_package ${source_directory} ${output_file} ${layer_versions}
elif [ -n "${package_runtime}" ]; then
  build_lambda_package ${source_directory} ${output_file} ${package_runtime}
fi

exit 0
