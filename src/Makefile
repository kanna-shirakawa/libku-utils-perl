all: ku-utils.pl ku-utils-realdates.pl

clean:
	rm -f ku-utils.pl ku-utils-realdates.pl

ku-utils.pl: __ku_utils_base.pl __ku_utils_simpledates.pl Makefile
	echo "# ku-utils.pl" >ku-utils.pl
	cat __ku_utils_base.pl __ku_utils_simpledates.pl >>ku-utils.pl
	/bin/echo -e "\n1;" >>ku-utils.pl
	@echo

ku-utils-realdates.pl: __ku_utils_base.pl __ku_utils_realdates.pl Makefile
	echo "# ku-utils-realdates.pl" >ku-utils-realdates.pl
	cat __ku_utils_base.pl __ku_utils_realdates.pl >>ku-utils-realdates.pl
	/bin/echo -e "\n1;" >>ku-utils-realdates.pl
	@echo

