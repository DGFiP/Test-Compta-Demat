#!/bin/sh
OLD_IFS=${IFS}
IFS="$(printf '\n')"
OLD_PATH=${PATH}

CMD_HOME_DIR="$(cd "$(dirname "$1")"; pwd -P)/"
GARBAGE_SCRIPT_PATH=${CMD_HOME_DIR}$(echo -n $0 | sed -e 's%'${CMD_HOME_DIR}'%%gm')
cd "$(dirname ${GARBAGE_SCRIPT_PATH})"

SCRIPT_PATH=$(pwd -P)
SCRIPT_NAME=$(basename ${GARBAGE_SCRIPT_PATH})
cd ..

SOURCE_DIR=$(pwd -P | sed 's/[]['\''!"#$%& ()*,:;<=>?`{|}~]/\\&/gm') # Escaping characters

cd "${SCRIPT_PATH}"

cat > ${SCRIPT_PATH}/environnement_alto2.pl <<EOL
#!/usr/bin/perl -- -*- C -*-
sub Env_Path {
		\$ENV{ProgramFiles} = "$SOURCE_DIR";
		\$ENV{ProgramData} = "$SOURCE_DIR";
}
1; #return true
EOL

if [ -f "init.exe" ]; then
  init.exe $1
  else
  perl init.pl $1
fi
IFS=${OLD_IFS}
export PATH="${OLD_PATH}"
=======
cd $(dirname $0)
export PATH=$PATH:.
#perl init.exe $1
perl init.pl $1
