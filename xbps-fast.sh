#!/bin/sh
# TMP_PREFIX=/tmp/xbps-fast/
# mkdir -pv ${TMP_PREFIX}

# TMP_CACHE=$(mktemp -u -p ${TMP_PREFIX})
# xbps-install -nD $@ > ${TMP_CACHE}

# cat ${TMP_CACHE} | cut -d' ' -f1

_MAXNUM=5
_MAXCONPERSRV=10
_SPLITCON=8
_MINSPLITSZ="1M"
_PIECEALGO="default"
DL_DIR=/var/cache/xbps-fast
DLLIST=/tmp/xbps-fast.list
_DOWNLOADER='echo aria2c --no-conf -c -j ${_MAXNUM} -x ${_MAXCONPERSRV} -s ${_SPLITCON} --min-split-size=${_MINSPLITSZ} --stream-piece-selector=${_PIECEALGO} -i ${DLLIST} --connect-timeout=600 --timeout=600 -m0 --header "Accept: */*" --user-agent "wget"'

ORIG_REPOS=$(xbps-query -L | grep -o 'http[^ ]*' | sed 's#current.*##g' | sort -u)
MIRRORS=(
      'https://mirrors.bfsu.edu.cn/voidlinux/'
      'https://mirrors.cnnic.cn/voidlinux/'
      'https://mirror.sjtu.edu.cn/voidlinux/'
      'https://mirrors.tuna.tsinghua.edu.cn/voidlinux/'
        )


get_mirrors(){
  # Check all mirror lists.
  for mirrorstr in "${MIRRORS[@]}"; do
    # Build mirrors array from comma separated string.
    IFS=", " read -r -a mirrors <<< "$mirrorstr"
    # Check for all mirrors if URI of $1 is from mirror. If so add all other
    # mirrors to (resmirror) list and break all loops.
    for mirror in "${mirrors[@]}"; do
      # Real expension.
      if [[ "$1" == "$mirror"* ]]; then
        filepath=${1#${mirror}}
        # Build list for aria download list.
        # list="${mirrors[*]}"
        list="${MIRRORS[*]}"
        echo -e "${list// /${filepath}\\t}$filepath\n"
        return 0
      fi
    done
  done
  # No other mirrors found.
  echo "$1"
}

mkdir ${DL_DIR}
cd ${DL_DIR}

rm -f ${DLLIST}

xbps-install -n $@ | while read line;do
  pkg_name=$(echo "$line" | cut -d' ' -f1)
  arch_name=$(echo "$line" | cut -d' ' -f3)
  repo_url=$(echo "$line" | cut -d' ' -f4)

  {
  get_mirrors ${repo_url}/${pkg_name}.${arch_name}.xbps
  echo " out=${pkg_name}.${arch_name}.xbps"
  get_mirrors ${repo_url}/${pkg_name}.${arch_name}.xbps.sig
  echo " out=${pkg_name}.${arch_name}.xbps.sig"
  } >> ${DLLIST}
done

eval "${_DOWNLOADER}"  # execute downloadhelper command
