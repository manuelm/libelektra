#!/bin/sh

if [ -z "$APP_PATH" ]; then
	# TODO: set APP_PATH to the installed path of your application
	APP_PATH='/usr/local/bin/tests_script_gen_highlevel_empty'
fi

if ! [ -f "$APP_PATH" ]; then
	echo "ERROR: APP_PATH points to non-existent file" 1>&2
	exit 1
fi

error_other_mp() {
	echo "ERROR: another mountpoint already exists on spec:/tests/script/gen/highlevel/empty. Please umount first." 1>&2
	exit 1
}

if kdb mount -13 | grep -Fxq 'spec:/tests/script/gen/highlevel/empty'; then
	if ! kdb mount | grep -Fxq 'tests_script_gen_highlevel_empty.overlay.spec.eqd on spec:/tests/script/gen/highlevel/empty with name spec:/tests/script/gen/highlevel/empty'; then
		error_other_mp
	fi

	MP=$(echo "spec:/tests/script/gen/highlevel/empty" | sed 's:\\:\\\\:g' | sed 's:/:\\/:g')
	if [ -n "$(kdb get "system:/elektra/mountpoints/$MP/getplugins/#5#specload#specload#/config/file")" ]; then
		error_other_mp
	fi
	if [ "$(kdb get "system:/elektra/mountpoints/$MP/getplugins/#5#specload#specload#/config/app")" != "$APP_PATH" ]; then
		error_other_mp
	fi
	if [ -n "$(kdb ls "system:/elektra/mountpoints/$MP/getplugins/#5#specload#specload#/config/app/args")" ]; then
		error_other_mp
	fi
else
	sudo kdb mount -R noresolver "tests_script_gen_highlevel_empty.overlay.spec.eqd" "spec:/tests/script/gen/highlevel/empty" specload "app=$APP_PATH"
fi

if kdb mount -13 | grep -Fxq '/tests/script/gen/highlevel/empty'; then
	if ! kdb mount | grep -Fxq 'tests_gen_elektra_empty.ini on /tests/script/gen/highlevel/empty with name /tests/script/gen/highlevel/empty'; then
		echo "ERROR: another mountpoint already exists on /tests/script/gen/highlevel/empty. Please umount first." 1>&2
		exit 1
	fi
else
	sudo kdb spec-mount '/tests/script/gen/highlevel/empty'
fi
