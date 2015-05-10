function el_name_to_distro_name()
{
	local EL="$1"
	if [[ "$EL" = el7 ]]; then
		echo centos7
	elif [[ "$EL" = el6 ]]; then
		echo centos6
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}

function distro_name_to_testbox_image()
{
	local DISTRIBUTION="$1"
	if [[ "$DISTRIBUTION" = centos7 ]]; then
		echo phusion/passenger_rpm_automation_testbox_centos_7
	elif [[ "$DISTRIBUTION" = centos6 ]]; then
		echo phusion/passenger_rpm_automation_testbox_centos_6
	else
		echo "ERROR: unknown distribution name." >&2
		return 1
	fi
}
