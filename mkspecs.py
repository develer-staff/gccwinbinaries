#!/usr/bin/env python

import sys
import os
import subprocess

mingw_path = sys.argv[1]
gcc_exe = os.path.join(mingw_path, "bin", "gcc.exe")
version = subprocess.Popen([gcc_exe, "-dumpversion"], stdout=subprocess.PIPE).communicate()[0].strip()
specs = subprocess.Popen([gcc_exe, "-dumpspecs"], stdout=subprocess.PIPE).communicate()[0].split("\r\n")
spec_path = os.path.join(mingw_path, "lib", "gcc", "mingw32", version)

for major, minor in [[6, 0], [7, 0], [7, 1], [8, 0], [9, 0]]:
	def write_spec(file, major, minor):
		define = "-D__MSVCRT_VERSION__=0x%02x%02x" % (major, minor)
		updated_specs = list(specs)
		updated_specs[specs.index("*cc1:") + 1] += " " + define
		open(file, "wt").write("\n".join(updated_specs))

	if major == 6:
		write_spec(os.path.join(spec_path, "specs"), major, minor)
	write_spec(os.path.join(spec_path, "specs" + str(major) + str(minor)), major, minor)
