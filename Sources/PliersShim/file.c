#include "file.h"
#include <errno.h>
#include <fcntl.h>
#include <grp.h>
#include <pwd.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

const int UNKNOWN_ERROR = 255;

void switch_user(struct passwd* pw) {
	if (pw->pw_uid != getuid()) {
		if (setgroups(0, NULL) != 0) _exit(errno);
		if (setgid(pw->pw_gid) != 0) _exit(errno);
		if (setuid(pw->pw_uid) != 0) _exit(errno);
	}
}

int wait_process(pid_t pid) {
	int status = 0;
	if (waitpid(pid, &status, 0) < 0) return errno;

	return WIFEXITED(status) ? WEXITSTATUS(status) : UNKNOWN_ERROR;
}

int check_access(int mode, const char* username, const char* path) {
	struct passwd* pw = getpwnam(username);
	if (!pw) return UNKNOWN_ERROR;

	pid_t pid = fork();
	if (pid < 0) return errno;

	if (pid == 0) {
		switch_user(pw);

		// `access` is async-signal-safe
		int result = access(path, mode);
		_exit(result == 0 ? 0 : errno);
	}

	return wait_process(pid);
}

int create_file(const char* username, const char* path) {
	struct passwd* pw = getpwnam(username);
	if (!pw) return UNKNOWN_ERROR;

	pid_t pid = fork();
	if (pid < 0) return errno;

	if (pid == 0) {
		switch_user(pw);

		// `open` is async-signal-safe, `fopen` is not
		int result = open(path, O_WRONLY | O_CREAT | O_EXCL, 0644);
		if (result >= 0) close(result);
		_exit(result >= 0 ? 0 : errno);
	}

	return wait_process(pid);
}

int create_dir(const char* username, const char* path) {
	struct passwd* pw = getpwnam(username);
	if (!pw) return UNKNOWN_ERROR;

	pid_t pid = fork();
	if (pid < 0) return errno;

	if (pid == 0) {
		switch_user(pw);

		// `mkdir` is async-signal-safe
		int result = mkdir(path, 0755);
		_exit(result == 0 ? 0 : errno);
	}

	return wait_process(pid);
}

int change_mode(const char* username, const char* path, mode_t mode) {
	struct passwd* pw = getpwnam(username);
	if (!pw) return UNKNOWN_ERROR;

	pid_t pid = fork();
	if (pid < 0) return errno;

	if (pid == 0) {
		switch_user(pw);

		// `chmod` is async-signal-safe
		int result = chmod(path, mode);
		_exit(result == 0 ? 0 : errno);
	}

	return wait_process(pid);
}
