#! /usr/bin/env python3

import helpers.nameConventions as names
import helpers.regex as myRE

if __name__ == '__main__':
	print("Now testing writer:")
	print(names.resDN())
	print(names.resDN("a"))
	print(names.resInnerDN("2"))
	print(names.resInnerDN("73"))
	try:
		print(names.resInnerDN("a"))
	except:
		print("Inner result directory error with \"a\".")

	print("Now testing reader:")
	print(
		myRE.getMatch(
			names.resDN(),
			myRE.compile( names.resDNRE )
		)
	)
	print(
		myRE.getMatch(
			names.resDN("a"),
			myRE.compile( names.resDNRE )
		)
	)
	print(
		myRE.getMatch(
			names.resInnerDN("2"),
			myRE.compile( names.resInnerDNRE )
		)
	)


# EOF
