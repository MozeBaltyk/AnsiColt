#!/bin/bash

# load images listed in deps/images.txt
printf "\e[1;34m[INFO]\e[m load images listed in meta/ee-images.tx.\n"

for line in $(cat ../../meta/ee-images.txt); do
  echo "### ${line} ###"
  image=$( echo "${line}" | awk  -F ";" '{print $1}' )
  dir=$( echo "${line}" | awk  -F ";" '{print $2}' )
  archive_name=$(basename -a $(awk -F : '{print $1}'<<<$image));
  echo "### Pull images ###"
  podman pull ${image}
  echo "### Push images in dir ${dir} ###"
  mkdir -p ../../$dir
  podman save ${image} --format oci-archive -o ../../$dir/$archive_name;
done

# load images from helm charts
for helm in $(ls ../../roles/*/files/helm/*.tgz); do
  printf "\e[1;34m[INFO]\e[m Look for images in ${helm}...\n"

  images=$(helm template -g $helm |yq -N '..|.image? | select(.)'|sort|uniq|grep ":"|egrep -v '*:[[:blank:]]')

  dir=$( dirname $helm | xargs dirname )

  echo "####"

  if [ "$images" != "" ]; then
    printf "\e[1;34m[INFO]\e[m Images found in the helm charts: ${images}\n"
    printf "\e[1;34m[INFO]\e[m Create ${dir}/images images...\n"

    mkdir -p ${dir}/images

    while i= read -r image_name; do
      archive_name=$(basename -a $(awk -F : '{print $1}'<<<${image_name}));
      printf "\e[1;34m[INFO]\e[m Pull images...\n"
      podman pull ${image_name};
      printf "\e[1;34m[INFO]\e[m Push ${image_name} in ${dir}/images/${archive_name}\n"
      podman save ${image_name} --format oci-archive -o ${dir}/images/${archive_name};
    done <<< ${images}
  fi
done