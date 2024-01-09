/*
 * getGuileVersion.c
 *
 * Copyright (C) 2022 Michael Schierl
 *
 * AutoGen is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the
 * Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Helper program to format GUILE_VERSION variable.
 */
#include <libguile/version.h>
#include <stdio.h>

int main() {
	printf("%u%02u%03u\n", SCM_MAJOR_VERSION, SCM_MINOR_VERSION, SCM_MICRO_VERSION);
	return 0;
}
