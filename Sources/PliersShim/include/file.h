#pragma once

#include <sys/types.h>

int check_access(int mode, const char* username, const char* path);
int create_file(const char* username, const char* path);
int create_dir(const char* username, const char* path);
int change_mode(const char* username, const char* path, __mode_t mode);
