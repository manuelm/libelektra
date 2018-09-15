/**
 * @file
 *
 * @brief
 *
 * @copyright BSD License (see LICENSE.md or https://www.libelektra.org)
 */

#include "path.h"

#ifndef HAVE_KDBCONFIG
#include "kdbconfig.h"
#include <pwd.h>
#endif

char* lastCharDel(char* name)
{
	int i = 0;
	while(name[i] != '\0')
	{
		i++;
	}
	name[i-1] = '\0';
	return name;
}

static int validateKey (Key * key, Key * parentKey)
{
	struct stat buf;
	/* TODO: make exceptions configurable using path/allow */
	if (!strcmp (keyString (key), "proc"))
	{
		return 1;
	}
	else if (!strcmp (keyString (key), "tmpfs"))
	{
		return 1;
	}
	else if (!strcmp (keyString (key), "none"))
	{
		return 1;
	}
	else if (keyString (key)[0] != '/')
	{
		ELEKTRA_SET_ERROR (56, parentKey, keyString (key));
		return 0;
	}
	int errnosave = errno;
	const Key * meta = keyGetMeta (key, "check/path");
	if (stat (keyString (key), &buf) == -1)
	{
		char * errmsg = elektraMalloc (ERRORMSG_LENGTH + 1 + +keyGetNameSize (key) + keyGetValueSize (key) +
						   sizeof ("name:  value:  message: "));
		strerror_r (errno, errmsg, ERRORMSG_LENGTH);
		strcat (errmsg, " from key: ");
		strcat (errmsg, keyName (key));
		strcat (errmsg, " with path: ");
		strcat (errmsg, keyValue (key));
		ELEKTRA_ADD_WARNING (57, parentKey, errmsg);
		elektraFree (errmsg);
		errno = errnosave;
	}
	else if (!strcmp (keyString (meta), "device"))
	{
		if (!S_ISBLK (buf.st_mode))
		{
			ELEKTRA_ADD_WARNING (54, parentKey, keyString (key));
		}
	}
	else if (!strcmp (keyString (meta), "directory"))
	{
		if (!S_ISDIR (buf.st_mode))
		{
			ELEKTRA_ADD_WARNING (55, parentKey, keyString (key));
		}
	}
	return 1;
}

//I assume the path exists and only validate permission
static int validatePermission(const char *path, Key * key, Key * parentKey)
{

	const Key * userMeta = keyGetMeta (key, "check/permission/user");
	const Key * userTypes = keyGetMeta (key, "check/permission/types");

	//***** To externalize *******
	const char *validPath = keyString (key);
	const char *name =  keyString (userMeta);
	const char *modes = keyString(userTypes);
	//****************************

	// Changing to specified user. Can only be done when executing user is root user
	if (name) {
		struct passwd *p = getpwnam(name);
		//Check if user exists
		if (p == NULL) {
			ELEKTRA_SET_ERRORF (205, parentKey, "Could not find user \"%s\" for key \"%s\". "
									   "Does the user exist?\"", name, keyName(key));
			return -1;
		}

		//Check if I can change the UID as root
		int err = seteuid((int) p->pw_uid);
		if (err < 0) {
			ELEKTRA_SET_ERRORF (206, parentKey, "Could not set uid of user \"%s\" for key \"%s\"."
									   " Are you running kdb as root?\"", keyString (userMeta), keyName(key));
			return -1;
		}
	}

	int isRead = (strchr(modes, 'r') == NULL) ? 0 : 1;
	int isWrite = (strchr(modes, 'w') == NULL) ? 0 : 1;
	int isExecute = (strchr(modes, 'x') == NULL) ? 0 : 1;

	char errorMessage[30];
	errorMessage[0] = '\0';	//strcat() searches for this, otherwise it will print garbage chars at start
	int isError = 0;

	if (euidaccess(validPath, R_OK) != 0) {
		isError = 1;
		strcat(errorMessage, "read,");
	}

	if (euidaccess(validPath, W_OK) != 0) {
		isError = 1;
		strcat(errorMessage, "write,");
	}

	if (euidaccess(validPath, X_OK) != 0) {
		isError = 1;
		strcat(errorMessage, "execute,");
	}

	if (isError) {
		ELEKTRA_SET_ERRORF (207, parentKey, "User %s does not have [%s] permission on %s", name,
							lastCharDel(errorMessage),
							validPath);
		return -1;
	}

	return 1;
}

int elektraPathGet (Plugin * handle ELEKTRA_UNUSED, KeySet * returned, Key * parentKey ELEKTRA_UNUSED)
{
	/* contract only */
	KeySet * n;
	ksAppend (returned, n = ksNew (30, keyNew ("system/elektra/modules/path", KEY_VALUE, "path plugin waits for your orders", KEY_END),
					   keyNew ("system/elektra/modules/path/exports", KEY_END),
					   keyNew ("system/elektra/modules/path/exports/get", KEY_FUNC, elektraPathGet, KEY_END),
					   keyNew ("system/elektra/modules/path/exports/set", KEY_FUNC, elektraPathSet, KEY_END),
					   keyNew ("system/elektra/modules/path/exports/validateKey", KEY_FUNC, validateKey, KEY_END),
#include "readme_path.c"
					   keyNew ("system/elektra/modules/path/infos/version", KEY_VALUE, PLUGINVERSION, KEY_END), KS_END));
	ksDel (n);

	return 1; /* success */
}

int elektraPathSet (Plugin * handle ELEKTRA_UNUSED, KeySet * returned, Key * parentKey)
{
	/* set all keys */
	Key * cur;
	ksRewind (returned);
	int rc = 1;
	while ((cur = ksNext (returned)) != 0)
	{
		const Key * pathMeta = keyGetMeta (cur, "check/path");
		if (!pathMeta) continue;
		rc = validateKey (cur, parentKey);
		if (!rc) return -1;

		const Key * accessMeta = keyGetMeta (cur, "check/permission/types");
		if (!accessMeta) continue;
		rc = validatePermission(keyString(pathMeta), cur, parentKey);
		if (!rc) return -1;
	}

	return 1; /* success */
}

Plugin * ELEKTRA_PLUGIN_EXPORT (path)
{
	// clang-format off
	return elektraPluginExport("path",
		ELEKTRA_PLUGIN_GET,	&elektraPathGet,
		ELEKTRA_PLUGIN_SET,	&elektraPathSet,
		ELEKTRA_PLUGIN_END);
}

