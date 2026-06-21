#include "access_control.h"
#include <grp.h>
#include <pwd.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

bool has_access(int mode, const char* username, const char* path) {
	struct passwd* pw = getpwnam(username);
	if (!pw) {
		return false;
	}

	pid_t pid = fork();
	if (pid < 0) {
		return false;
	}

	if (pid == 0) {
		if (initgroups(pw->pw_name, pw->pw_gid) != 0) _exit(EXIT_FAILURE);
		if (setgid(pw->pw_gid) != 0) _exit(EXIT_FAILURE);
		if (setuid(pw->pw_uid) != 0) _exit(EXIT_FAILURE);

		int result = access(path, mode);
		_exit(result == 0 ? EXIT_SUCCESS : EXIT_FAILURE);
	}

	int status = 0;
	if (waitpid(pid, &status, 0) < 0) {
		return false;
	}

	bool exited = WIFEXITED(status);
	int code = WEXITSTATUS(status);

	return exited && code == EXIT_SUCCESS;
}
