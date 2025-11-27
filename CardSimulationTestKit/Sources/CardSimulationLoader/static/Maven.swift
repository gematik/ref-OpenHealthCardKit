//
// Copyright (Change Date see Readme), gematik GmbH
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *******
//
// For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

// This static shell script is supposed to be run by the SimulationManager when installing
// the G2-Kartensimulation jar files. Unfortunately we cannot add this as a script file in a Bundle resource as the
// SwiftPM won't include it in the target's framework

internal let runMavenSh = """
#!/bin/bash

#set -x

# Check for mvn availability
export PATH=$PATH:/usr/bin/:/usr/local/bin/:/opt/homebrew/bin/
hash mvn >/dev/null 2>&1 || {
  echo >&2 "For running CardSimulation we need to download Maven dependencies.
  But maven was not found. Looked in PATH: ${PATH}).
  Please check your shell environment settings or Xcode Run scheme for mvn command.
  If maven is not installed, please install maven. For instance with brew: $ brew install maven.
  Aborting.";
  exit 1;
}

# Check POM_PATH parameter
if [ -z "$1" ]; then
  echo "Please specify a POM path."
  exit 1
fi

POM_DIR="$(dirname $1)"

MVN_COMMAND="mvn dependency:copy-dependencies" || {
  echo >&2 "Before executing a Maven goal, Maven has to be configured accordingly.
  Please check your whether the correct settings.xml and settings-security.xml exist in $HOME/.m2 directory.
  Aborting.";
  exit 1;
}

cd "${POM_DIR}" && ${MVN_COMMAND}
"""
