#!/bin/bash
# DO NOT EDIT!!
# 
# This file is automatically generated from internal/lib/distro_info.sh.erb,
# and definitions from internal/lib/docker_image_info.sh.
#
# Edit those and regenerate distro_info.sh by running:
# internal/scripts/regen_distro_info_script.sh
DEFAULT_DISTROS="el7 el8"


function get_buildbox_image()
{
  echo "phusion/passenger_rpm_automation_buildbox:1.0.8"
}

function el_name_to_distro_name()
{
	local EL="$1"

	if [[ "$EL" =~ ^el[0-9]+$ ]]; then
		echo centos${EL#"el"}
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}

function distro_name_to_el_name()
{
	local DISTRIBUTION="$1"

	if [[ "$DISTRIBUTION" =~ ^centos[0-9]+$ ]]; then
		echo el${DISTRIBUTION#"centos"}
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}

function distro_name_to_testbox_image()
{
	local DISTRIBUTION="$1"
	if [[ "$DISTRIBUTION" =~ ^centos[0-9]+$ ]]; then
		echo phusion/passenger_rpm_automation_testbox_centos_${DISTRIBUTION#"centos"}:1.0.3
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}

function dynamic_module_supported()
{
	local CODENAME=$(distro_name_to_el_name "$1")

	
		if [[ "$CODENAME" = "el7" ]]; then
			echo true
			return
		fi
	
		if [[ "$CODENAME" = "el8" ]]; then
			echo true
			return
		fi
	

	echo false
}
